import 'dart:async';
import 'dart:convert';
import 'package:chating_app/data/user.dart';
import 'package:chating_app/services/chat_api.dart';
import 'package:chating_app/services/notification_service.dart';
import 'package:http/http.dart' as http;

class NotificationPoller {
  final ObjectUser user;
  final Set<String> _knownGroupIds = {};
  final Map<String, String> _groupNames = {};
  int _previousRequestCount = 0;
  Timer? _friendRequestTimer;
  bool _running = true;

  NotificationPoller(this.user);

  void start() {
    _checkGroupsLoop();
    _startFriendRequestPolling();
  }

  void stop() {
    _running = false;
    _friendRequestTimer?.cancel();
  }

  void _startFriendRequestPolling() {
    _friendRequestTimer =
        Timer.periodic(const Duration(seconds: 10), (_) async {
          try {
            final res = await http.get(Uri.parse(
                "http://138.2.106.32/contact/requests?userId=${user.userID}"));
            if (res.statusCode == 200) {
              final data = jsonDecode(res.body);
              final List requests = data['data'];
              if (requests.length > _previousRequestCount) {
                NotificationService.showBanner("Có lời mời kết bạn mới!");
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
      await Future.delayed(const Duration(seconds: 1));
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
          NotificationService.showBanner("Bạn đã bị đuổi khỏi nhóm \"$name\"");
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