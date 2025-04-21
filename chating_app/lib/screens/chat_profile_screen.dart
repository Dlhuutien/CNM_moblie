import 'package:chating_app/screens/create_group_screen.dart';
import 'package:chating_app/services/chat_api.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatProfileScreen extends StatefulWidget {
  final String chatId;
  final String userId;

  const ChatProfileScreen(
      {super.key, required this.chatId, required this.userId});

  @override
  State<ChatProfileScreen> createState() => _ChatProfileScreenState();
}

class _ChatProfileScreenState extends State<ChatProfileScreen> {
  Map<String, dynamic>? partnerInfo;
  List<String> imageUrls = [];
  List<Map<String, dynamic>> fileMessages = [];
  List<Map<String, dynamic>> linkMessages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      final partner =
          await ChatApi.loadPartnerInfo(widget.chatId, widget.userId);
      final messages =
          await ChatApi.fetchMessages(widget.chatId, widget.userId);

      final images = <String>[];
      final files = <Map<String, dynamic>>[];
      final links = <Map<String, dynamic>>[];

      for (var msg in messages) {
        final isDeleted = msg['deleteReason'] == 'unsent' ||
            (msg['deleteReason'] == 'remove' &&
                msg['userId'].toString() == widget.userId);
        if (isDeleted) continue;

        final url = msg['attachmentUrl']?.toString() ?? '';
        final content = msg['content']?.toString() ?? '';

        if (msg['type'] == 'attachment' && url.isNotEmpty) {
          final ext = url.split('.').last.toLowerCase();
          if (["jpg", "jpeg", "png", "gif", "webp"].contains(ext)) {
            images.add(url);
          } else {
            files.add(msg);
          }
        }

        if (RegExp(r'https?:\/\/').hasMatch(content)) {
          links.add(msg);
        }
      }

      setState(() {
        partnerInfo = partner;
        imageUrls = images;
        fileMessages = files;
        linkMessages = links;
      });
    } catch (e) {
      print("Lỗi khi load dữ liệu profile: $e");
    }
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CreateGroupScreen(userId: widget.userId)),
                  );
                }
            ),
            const ListTile(
              leading: Icon(Icons.block, color: Colors.red),
              title: Text("Block", style: TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 10),
            const Text("Shared Images",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                return Image.network(imageUrls[index], fit: BoxFit.cover);
              },
            ),
            const SizedBox(height: 20),
            const Text("Shared Links",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Column(
              children: linkMessages.map((msg) {
                final content = msg['content'] ?? '';
                final match = RegExp(r'https?:\/\/[^\s]+').firstMatch(content);
                final url = match?.group(0);
                return url != null
                    ? ListTile(
                        leading: const Icon(Icons.link, color: Colors.blue),
                        title: Text(url,
                            style: const TextStyle(color: Colors.blue)),
                        onTap: () async {
                          final uri = Uri.tryParse(url);
                          if (uri != null && await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                      )
                    : const SizedBox.shrink();
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text("Shared Files",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Column(
              children: fileMessages.map((msg) {
                final url = msg['attachmentUrl'];
                final fileName = Uri.parse(url).pathSegments.last;
                return ListTile(
                  leading: const Icon(Icons.attach_file, color: Colors.grey),
                  title: Text(fileName, overflow: TextOverflow.ellipsis),
                  onTap: () async {
                    final uri = Uri.tryParse(url);
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}


