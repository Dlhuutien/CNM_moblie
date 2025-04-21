import 'package:chating_app/screens/list_member.dart';
import 'package:flutter/material.dart';
import 'package:chating_app/services/chat_api.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatGroupProfileScreen extends StatefulWidget {
  final String chatId;
  final String userId;


  const ChatGroupProfileScreen({super.key, required this.chatId, required this.userId});

  @override
  State<ChatGroupProfileScreen> createState() => _ChatGroupProfileScreenState();
}

class _ChatGroupProfileScreenState extends State<ChatGroupProfileScreen> {
  List<Map<String, dynamic>> members = [];
  List<String> imageUrls = [];
  List<Map<String, dynamic>> fileMessages = [];
  List<Map<String, dynamic>> linkMessages = [];
  String groupName = "";
  String groupDescription = "";
  String groupImageUrl = "";
  String currentRole = "";
  bool isLoading = true;

  bool get isOwner => currentRole == 'owner';
  bool get isAdmin => currentRole == 'admin' || isOwner;
  bool get isMember => currentRole == 'member';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final response = await ChatApi.getGroupMembers(widget.chatId, widget.userId);
      final messages = await ChatApi.fetchMessages(widget.chatId, widget.userId);

      final currentUser = response.firstWhere((m) => m['userId'].toString() == widget.userId, orElse: () => {});
      currentRole = currentUser['role'] ?? '';

      final images = <String>[];
      final files = <Map<String, dynamic>>[];
      final links = <Map<String, dynamic>>[];

      for (var msg in messages) {
        final isDeleted = msg['deleteReason'] == 'unsent' ||
            (msg['deleteReason'] == 'remove' && msg['userId'].toString() == widget.userId);
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
        members = response;
        groupName = "Designer Team"; // Replace with real group name
        groupDescription = "This is the description"; // Replace with real desc
        groupImageUrl = members.isNotEmpty ? members.first['imageUrl'] ?? '' : '';
        imageUrls = images;
        fileMessages = files;
        linkMessages = links;
        isLoading = false;
      });
    } catch (e) {
      print("Lỗi khi load dữ liệu nhóm: $e");
    }
  }

  void _disbandGroup() async {
    final confirmed = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Disband Group"),
        content: const Text("Are you sure you want to disband this group?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Disband")),
        ],
      ),
    );
    if (confirmed == true) {
      await ChatApi.disbandGroup(widget.chatId, widget.userId);
      Navigator.pop(context);
    }
  }

  void _leaveGroup() async {
    await ChatApi.removeGroupMember(widget.chatId, widget.userId, widget.userId);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Profile"),
        actions: const [
          Icon(Icons.call),
          SizedBox(width: 8),
          Icon(Icons.push_pin),
          SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(groupImageUrl),
            ),
            const SizedBox(height: 8),
            Text(groupName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(groupDescription, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            ListTile(leading: const Icon(Icons.edit), title: const Text("Change group name")),
            ListTile(leading: const Icon(Icons.description), title: const Text("Change description")),
            if (isAdmin)
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text("Add new member"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ListMemberScreen(
                        userId: widget.userId,
                        chatId: widget.chatId,
                      ),
                    ),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: Text(isOwner ? "Disband Group" : "Leave Group", style: const TextStyle(color: Colors.red)),
              onTap: isOwner ? _disbandGroup : _leaveGroup,
            ),
            const Divider(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Members (${members.length})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ListMemberScreen(
                          userId: widget.userId,
                          chatId: widget.chatId,
                          initialTabIndex: 1, // hiển thị tab "Members"
                        ),
                      ),
                    );
                  },
                  child: const Text("Show All"),
                )
              ],
            ),
            const SizedBox(height: 8),
            ...members.map((m) => ListTile(
              leading: CircleAvatar(backgroundImage: NetworkImage(m['imageUrl'] ?? '')),
              title: Text(m['name'] ?? ''),
              subtitle: Text(m['role'] ?? ''),
            )),

            const Divider(),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Shared Images", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
              itemCount: imageUrls.length,
              itemBuilder: (context, index) {
                return Image.network(imageUrls[index], fit: BoxFit.cover);
              },
            ),

            const Divider(),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Shared Links", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ...linkMessages.map((msg) {
              final url = RegExp(r'https?:\/\/[^\s]+').firstMatch(msg['content'] ?? '')?.group(0);
              return url != null
                  ? ListTile(
                leading: const Icon(Icons.link, color: Colors.blue),
                title: Text(url, style: const TextStyle(color: Colors.blue)),
                onTap: () async {
                  final uri = Uri.tryParse(url);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              )
                  : const SizedBox.shrink();
            }),

            const Divider(),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Shared Files", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ...fileMessages.map((msg) {
              final url = msg['attachmentUrl'];
              final fileName = Uri.parse(url).pathSegments.last;
              return ListTile(
                leading: const Icon(Icons.attach_file, color: Colors.grey),
                title: Text(fileName, overflow: TextOverflow.ellipsis),
                onTap: () async {
                  final uri = Uri.tryParse(url);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}