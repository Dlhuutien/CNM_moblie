import 'package:chating_app/screens/create_group_screen.dart';
import 'package:chating_app/services/chat_api.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:chating_app/widgets/full_screen_image.dart';

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
      print("Error loading profile data: $e");
    }
  }

  ///Hàm mở file, link
  Future<void> openFileUrl(BuildContext context, String url) async {
    if (!await Permission.manageExternalStorage.isGranted) {
      final granted = await Permission.manageExternalStorage.request();
      if (!granted.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("File management permission required to open."),
            action: SnackBarAction(
              label: "Setting",
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        return;
      }
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("URL không hợp lệ.")),
      );
      return;
    }

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to open file. Make sure you have the correct application.")),
      );
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
                    MaterialPageRoute(builder: (context) =>
                        CreateGroupScreen(
                          userId: widget.userId,
                          initialSelectedUserId: partnerInfo?['userId']?.toString(),)),
                  );
                }
            ),
            const ListTile(
              leading: Icon(Icons.block, color: Colors.red),
              title: Text("Block", style: TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Shared Images", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
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
                final url = imageUrls[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImage(imageUrl: url)));
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(url, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
                      return const Center(child: Icon(Icons.broken_image));
                    }),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Shared Links", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
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
                            style: const TextStyle(color: Colors.blue),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,),
                            onTap: () => openFileUrl(context, url),
                )
                    : const SizedBox.shrink();
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Shared Files", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            Column(
              children: fileMessages.map((msg) {
                final url = msg['attachmentUrl'];
                final fileName = Uri.parse(url).pathSegments.last;
                return ListTile(
                  leading: const Icon(Icons.attach_file, color: Colors.grey),
                  title: Text(fileName, overflow: TextOverflow.ellipsis),
                  onTap: () => openFileUrl(context, url),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}


