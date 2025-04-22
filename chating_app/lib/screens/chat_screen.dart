import 'dart:async';
import 'package:chating_app/data/user.dart';
import 'package:flutter/material.dart';
import 'package:chating_app/services/chat_api.dart';
import 'chat_detail_screen.dart';
import 'package:flutter/foundation.dart';

class ChatScreen extends StatefulWidget {
  final ObjectUser user;

  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String _selectedTab = "All";
  Timer? _refreshTimer;
  List<Map<String, dynamic>> _chats = [];

  @override
  void initState() {
    super.initState();
    _loadChats();
    _refreshTimer = Timer.periodic(Duration(seconds: 1), (_) => _loadChats());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadChats() async {
    final newList = await ChatApi.fetchChatsWithLatestMessage(widget.user.userID);

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
      final msg = chat["latestMessage"]?["Content"] ?? "";
      if (msg.toString().trim().isEmpty) return false;
      if (_selectedTab == "All") return true;
      if (_selectedTab == "Group") return chat["ChatID"].toString().startsWith("group-");
      if (_selectedTab == "Unread") return chat["isUnread"] == true;
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
                _buildTab("All", isSelected: _selectedTab == "All"),
                _buildTab("Unread", isSelected: _selectedTab == "Unread"),
                _buildTab("Group", isSelected: _selectedTab == "Group"),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Text("Messages", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              message: chat["latestMessage"]?["Content"] ?? "",
              time: _formatTime(chat["latestMessage"]?["Timestamp"]),
              isGroup: chat["ChatID"].toString().startsWith("group-"),
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
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: avatarUrl.isNotEmpty
            ? NetworkImage(avatarUrl)
            : const AssetImage('assets/profile.png') as ImageProvider,
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(message, overflow: TextOverflow.ellipsis),
      trailing: Text(time, style: const TextStyle(fontSize: 12)),
      onTap: () {
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
