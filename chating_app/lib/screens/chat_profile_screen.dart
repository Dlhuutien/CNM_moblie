import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatProfileScreen extends StatefulWidget {
  final String chatId;
  final String userId;

  const ChatProfileScreen({super.key, required this.chatId, required this.userId});

  @override
  State<ChatProfileScreen> createState() => _ChatProfileScreenState();
}

class _ChatProfileScreenState extends State<ChatProfileScreen> {
  Map<String, dynamic>? partnerInfo;
  List<String> imageUrls = [];

  @override
  void initState() {
    super.initState();
    _loadPartnerInfo();
  }

  Future<void> _loadPartnerInfo() async {
    final url = Uri.parse("http://138.2.106.32/chat/${widget.chatId}/info?userId=${widget.userId}");
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final members = data['data']['members'] as List<dynamic>;
      final messages = await _loadChatMessages();
      final currentUserId = widget.userId;

      // Tìm người đang chat với mình
      final partner = members.firstWhere((m) => m['userId'].toString() != currentUserId);

      setState(() {
        partnerInfo = partner;
        imageUrls = messages
            .where((msg) => msg['type'] == 'attachment' && msg['attachmentUrl'] != null)
            .map<String>((msg) => msg['attachmentUrl'] as String)
            .toList();
      });
    }
  }

  Future<List<dynamic>> _loadChatMessages() async {
    final historyUrl = Uri.parse("http://138.2.106.32/chat/${widget.chatId}/history/50?userId=${widget.userId}");
    final res = await http.get(historyUrl);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['data'] as List<dynamic>;
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    if (partnerInfo == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.push_pin),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(partnerInfo!['imageUrl'] ?? ''),
            ),
            const SizedBox(height: 10),
            Text(
              partnerInfo!['name'] ?? 'No name',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              partnerInfo!['email'] ?? 'No email',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.phone),
              title: Text(partnerInfo!['phone'] ?? 'No phone'),
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: Text(partnerInfo!['location'] ?? 'No location'),
            ),
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text("Create group"),
            ),
            const ListTile(
              leading: Icon(Icons.block, color: Colors.red),
              title: Text("Block", style: TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 20),
            const Text(
              "Shared Images",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: imageUrls.length,
              itemBuilder: (context, index) {
                return Image.network(
                  imageUrls[index],
                  fit: BoxFit.cover,
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("Links", style: TextStyle(fontSize: 16)),
                Icon(Icons.add),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("Files", style: TextStyle(fontSize: 16)),
                Icon(Icons.add),
              ],
            ),
          ],
        ),
      ),
    );
  }
}