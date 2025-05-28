import 'dart:async';
import 'package:chating_app/data/user.dart';
import 'package:flutter/material.dart';
import 'package:chating_app/services/chat_api.dart';
import 'chat_detail_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  final ObjectUser user;

  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String _selectedTab = "All".tr();
  Timer? _refreshTimer;
  List<Map<String, dynamic>> _chats = [];

  @override
  void initState() {
    super.initState();
    _loadChats();
    _refreshTimer = Timer.periodic(Duration(seconds: 5), (_) {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        _loadChats();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadChats() async {
    final prefs = await SharedPreferences.getInstance();

    final newList = await ChatApi.fetchChatsWithLatestMessage(widget.user.userID);

    if (!mounted) return;

    for (var chat in newList) {
      final chatId = chat["ChatID"];
      final lastReadTime = prefs.getString('lastReadTime_${widget.user.userID}_$chatId');
      final lastMessageTime = chat["lastMessage"]?["timestamp"];

      if (lastMessageTime == null) {
        chat["isUnread"] = false;
      } else if (lastReadTime == null) {
        chat["isUnread"] = true;
      } else {
        final lastMsgDt = DateTime.parse(lastMessageTime);
        final lastReadDt = DateTime.parse(lastReadTime);
        chat["isUnread"] = lastMsgDt.isAfter(lastReadDt);
      }
    }

    if (!listEquals(newList, _chats)) {
      setState(() {
        _chats = newList;
      });
    }
  }

  String _formatTime(String? iso) {
    if (iso == null || iso.isEmpty) return "";
    try {
      final dt = DateTime.parse(iso).toLocal();
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return "$hour:$minute";
    } catch (_) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredChats = _chats
        .where((chat) => chat["Status"] != "disbanded")
        .where((chat) {
      final isGroup = chat["ChatID"].toString().startsWith("group-");
      final hasMessage = (chat["lastMessage"]?["content"] ?? "").toString().trim().isNotEmpty;

      // Ẩn chat cá nhân chưa có tin nhắn
      if (!isGroup && !hasMessage) return false;

      if (_selectedTab == "All".tr()) return true;
      if (_selectedTab == "Group".tr()) return isGroup;
      if (_selectedTab == "Unread".tr()) return chat["isUnread"] == true;

      return true;
    })
        .toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tabs
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTab("All".tr(), isSelected: _selectedTab == "All".tr()),
                _buildTab("Unread".tr(), isSelected: _selectedTab == "Unread".tr()),
                _buildTab("Group".tr(), isSelected: _selectedTab == "Group".tr()),
              ],
            ),
          ),
           Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Text("Messages".tr(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),

          if (_chats.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.only(top: 50),
              child: CircularProgressIndicator(),
            )),

          for (var chat in filteredChats)
            _buildMessageTile(
              context: context,
              chatId: chat["ChatID"],
              avatarUrl: chat["imageUrl"] ?? "",
              name: chat["chatName"],
              message: chat["lastMessage"]?["content"] ?? "",
              time: _formatTime(chat["lastMessage"]?["timestamp"]),
              isGroup: chat["ChatID"].toString().startsWith("group-"),
              isUnread: chat["isUnread"] ?? false,
            ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, {required bool isSelected}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageTile({
    required BuildContext context,
    required String chatId,
    required String avatarUrl,
    required String name,
    required String message,
    required String time,
    required bool isGroup,
    required bool isUnread,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: avatarUrl.isNotEmpty
            ? NetworkImage(avatarUrl)
            : const AssetImage('assets/profile.png') as ImageProvider,
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(message, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(time, style: const TextStyle(fontSize: 12)),
          if (isUnread)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(Icons.circle, size: 8, color: Colors.blue),
            ),
        ],
      ),
      onTap: () async {
        final prefs = await SharedPreferences.getInstance();
        final nowIsoString = DateTime.now().toUtc().toIso8601String();

        // Lưu thời điểm đọc cuối của chat này
        await prefs.setString('lastReadTime_${widget.user.userID}_$chatId', nowIsoString);

        // Cập nhật UI
        _loadChats();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              name: name,
              chatId: chatId,
              userId: widget.user.userID,
              user: widget.user,
              isGroup: isGroup,
            ),
          ),
        );
      },
    );
  }
}
