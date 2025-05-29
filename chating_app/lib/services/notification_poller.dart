import 'dart:async';
import 'dart:convert';
import 'package:chating_app/data/user.dart';
import 'package:chating_app/services/chat_api.dart';
import 'package:chating_app/services/notification_service.dart';
import 'package:http/http.dart' as http;
import 'package:chating_app/services/env_config.dart';

class NotificationPoller {
  final ObjectUser user;
  final Set<String> _knownGroupIds = {};
  final Map<String, String> _groupNames = {};
  Map<String, String> _lastMessageTimestamps = {};
  int _previousRequestCount = 0;
  Timer? _friendRequestTimer;
  bool _running = true;

  NotificationPoller(this.user);

  void start() {
    _checkGroupsLoop();
    _startFriendRequestPolling();
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!_running) {
        timer.cancel();
        return;
      }
      _checkNewMessages();
    });
  }

  void stop() {
    _running = false;
    _friendRequestTimer?.cancel();
  }

  Future<void> _checkNewMessages() async {
    try {
      final chats = await ChatApi.fetchChatsWithLatestMessage(user.userID);
      for (var chat in chats) {
        final chatId = chat["ChatID"].toString();
        final lastMsg = chat["lastMessage"];
        final lastMsgTimestamp = lastMsg["timestamp"]?.toString();
        final senderId = lastMsg["userId"]?.toString();

        if (lastMsgTimestamp == null || senderId == null) continue;

        // Nếu tin nhắn mới do chính user gửi thì không hiện thông báo
        if (senderId == user.userID.toString()) continue;

        final previousTimestamp = _lastMessageTimestamps[chatId];

        // Nếu lần đầu hoặc có tin nhắn mới hơn
        if (previousTimestamp == null || lastMsgTimestamp.compareTo(previousTimestamp) > 0) {
          // Cập nhật timestamp mới
          _lastMessageTimestamps[chatId] = lastMsgTimestamp;

          // Nếu không phải lần đầu (để tránh thông báo lần đầu load)
          if (previousTimestamp != null) {
            final chatName = chat["chatName"] ?? "Cuộc trò chuyện";
            final message = chat["lastMessage"]?["content"] ?? "";

            await NotificationService.showLocalNotification(
              "Tin nhắn mới từ $chatName",
              message,
            );
          }
        }
      }
    } catch (e) {
      print("Lỗi khi kiểm tra tin nhắn mới: $e");
    }
  }

  void _startFriendRequestPolling() {

    _friendRequestTimer =
        Timer.periodic(const Duration(seconds: 10), (_) async {
          try {
            final baseUrl = EnvConfig.baseUrl;
            final url = "$baseUrl/contact/requests?userId=${user.userID}";
            final res = await http.get(Uri.parse(url));
            if (res.statusCode == 200) {
              final data = jsonDecode(res.body);
              final List requests = data['data'];
              if (requests.length > _previousRequestCount) {
                NotificationService.showBanner("Có lời mời kết bạn mới!");
                await NotificationService.showLocalNotification("Có lời mời kết bạn mới!", "Bạn có một lời mời kết bạn mới!");
              }
              _previousRequestCount = requests.length;
            }
          } catch (e) {
            print("Lỗi khi polling lời mời kết bạn: $e");
          }
        });
  }

  void _checkGroupsLoop() async {
    while (_running) {
      await Future.delayed(const Duration(seconds: 10));
      try {
        // Lấy danh sách tất cả các nhóm hiện tại
        final chats = await ChatApi.fetchChatsWithLatestMessage(user.userID);
        final groups = chats
            .where((c) => c["ChatID"].toString().startsWith("group-"))
            .toList();

        // Danh sách ID nhóm hiện tại
        final currentGroupIds = groups.map((g) => g["ChatID"].toString())
            .toSet();

        // PHÁT HIỆN NHÓM BỊ XÓA (đuổi ra)
        final removedGroupIds = _knownGroupIds.difference(currentGroupIds);
        for (var groupId in removedGroupIds) {
          final name = _groupNames[groupId] ?? "một nhóm";
          NotificationService.showBanner("Bạn đã ra khỏi nhóm \"$name\"");
          await NotificationService.showLocalNotification(
            "Thoát nhóm",
            "Bạn đã bị xoá khỏi nhóm \"$name\"",
          );
        }

        // CẬP NHẬT TÊN NHÓM (chỉ cập nhật sau khi xử lý removedGroupIds)
        for (var g in groups) {
          _groupNames[g["ChatID"].toString()] = g["chatName"] ?? "Không rõ";
        }

        // PHÁT HIỆN NHÓM MỚI
        final newGroups = groups
            .where((g) => !_knownGroupIds.contains(g["ChatID"].toString()))
            .toList();
        for (var group in newGroups) {
          NotificationService.showBanner(
              "Bạn đã được thêm vào nhóm \"${group["chatName"]}\"");
          NotificationService.showLocalNotification("Nhóm mới", "Bạn đã được thêm vào nhóm \"${group["chatName"]}\"");
        }

        // Cập nhật lại danh sách nhóm đã biết
        _knownGroupIds
          ..clear()
          ..addAll(currentGroupIds);
      } catch (e) {
        print("Lỗi kiểm tra nhóm mới: $e");
      }
    }
  }
}