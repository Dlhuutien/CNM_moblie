// import 'package:flutter/material.dart';
// import 'chat_detail_screen.dart';
//
// class ChatScreen extends StatelessWidget {
//   const ChatScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Tabs (All, Unread, Group)
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 _buildTab("All", isSelected: true),
//                 _buildTab("Unread", isSelected: false),
//                 _buildTab("Group", isSelected: false),
//               ],
//             ),
//           ),
//
//           // Pinned Messages Section
//           const Padding(
//             padding: EdgeInsets.symmetric(horizontal: 16.0),
//             child: Text(
//               "Pinned Messages",
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//           ),
//           const SizedBox(height: 10),
//           _buildMessageTile(
//             context: context,
//             avatarUrl: "https://",
//             name: "Indian Guy",
//             message: "Hello",
//             time: "6.00AM",
//             isPinned: true,
//           ),
//
//           // Messages Section
//           const Padding(
//             padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
//             child: Text(
//               "Messages",
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//           ),
//           _buildMessageTile(
//             context: context,
//             avatarUrl: "https://",
//             name: "Indian Guy",
//             message: "Hello",
//             time: "6.00AM",
//           ),
//           _buildMessageTile(
//             context: context,
//             avatarUrl: "https://",
//             name: "White Guy",
//             message: "Let's eat something",
//             time: "6.00AM",
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Helper widget to build tabs
//   Widget _buildTab(String label, {required bool isSelected}) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//       decoration: BoxDecoration(
//         color: isSelected ? Colors.blue : Colors.grey[200],
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Text(
//         label,
//         style: TextStyle(
//           color: isSelected ? Colors.white : Colors.black,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     );
//   }
//
//   // Helper widget to build a message tile
//   Widget _buildMessageTile({
//     required BuildContext context,
//     required String avatarUrl,
//     required String name,
//     required String message,
//     required String time,
//     bool isPinned = false,
//   }) {
//     return ListTile(
//       leading: CircleAvatar(
//         backgroundImage: NetworkImage(avatarUrl),
//       ),
//       title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
//       subtitle: Text(message, overflow: TextOverflow.ellipsis),
//       trailing: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           if (isPinned)
//             const Icon(Icons.push_pin, size: 16, color: Colors.grey),
//           Text(time, style: const TextStyle(fontSize: 12)),
//         ],
//       ),
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => ChatDetailScreen(name: name),
//           ),
//         );
//       },
//     );
//   }
// }
import 'dart:convert';
import 'package:chating_app/data/user.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'chat_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  final ObjectUser user;

  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final String baseUrl = "http://138.2.106.32";

  Future<List<Map<String, dynamic>>> fetchChatsWithLatestMessage() async {
    final userId = widget.user.userID;

    final response = await http.get(Uri.parse("$baseUrl/chat/me?userId=$userId"));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List chats = data["data"];
      List<Map<String, dynamic>> chatsWithMessages = [];

      for (var chat in chats) {
        final chatId = chat["ChatID"];
        final infoResponse = await http.get(Uri.parse("$baseUrl/chat/$chatId/info?userId=$userId"));

        if (infoResponse.statusCode == 200) {
          final infoData = json.decode(infoResponse.body);
          final latestMessage = infoData["data"]["latestMessage"];
          chat["latestMessage"] = latestMessage;
          chatsWithMessages.add(chat);
        }
      }

      return chatsWithMessages;
    } else {
      throw Exception("Failed to fetch chat list");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchChatsWithLatestMessage(),
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
