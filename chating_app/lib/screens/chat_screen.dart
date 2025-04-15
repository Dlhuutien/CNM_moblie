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
                    _buildTab("All", isSelected: true),
                    _buildTab("Unread", isSelected: false),
                    _buildTab("Group", isSelected: false),
                  ],
                ),
              ),

              // Messages section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: Text("Messages", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),

              for (var chat in chats)
                _buildMessageTile(
                  context: context,
                  chatId: chat["ChatID"],
                  avatarUrl: chat["imageUrl"] ?? "",
                  name: chat["chatName"],
                  message: chat["latestMessage"]?["Content"] ?? "",
                  time: chat["latestMessage"]?["Timestamp"]?.substring(11, 16) ?? "",
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTab(String label, {required bool isSelected}) {
    return Container(
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
    );
  }

  Widget _buildMessageTile({
    required BuildContext context,
    required String chatId,
    required String avatarUrl,
    required String name,
    required String message,
    required String time,
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
            builder: (context) => ChatDetailScreen(
              name: name,
              chatId: chatId,
              userId: widget.user.userID,
            ),
          ),
        );
      },
    );
  }
}
