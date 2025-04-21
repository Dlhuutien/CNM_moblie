import 'package:chating_app/data/user.dart';
import 'package:flutter/material.dart';
import 'package:chating_app/services/chat_api.dart';
import 'chat_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  final ObjectUser user;

  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String _selectedTab = "All";

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ChatApi.fetchChatsWithLatestMessage(widget.user.userID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final chats = snapshot.data ?? [];

        // Lọc theo tab
        final filteredChats = chats.where((chat) {
          if (_selectedTab == "All") return true;
          if (_selectedTab == "Group") return chat["ChatID"].toString().startsWith("group-");
          if (_selectedTab == "Unread") return chat["isUnread"] == true; // Nếu có field này
          return true;
        }).toList();

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

              for (var chat in filteredChats)
                _buildMessageTile(
                  context: context,
                  chatId: chat["ChatID"],
                  avatarUrl: chat["imageUrl"] ?? "",
                  name: chat["chatName"],
                  message: chat["latestMessage"]?["Content"] ?? "",
                  time: chat["latestMessage"]?["Timestamp"]?.substring(11, 16) ?? "",
                  isGroup: chat["ChatID"].toString().startsWith("group-"),
                ),
            ],
          ),
        );
      },
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
              isGroup: isGroup,
            ),
          ),
        );
      },
    );
  }
}
