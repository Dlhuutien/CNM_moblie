import 'dart:convert';
import 'package:chating_app/data/user.dart';
import 'package:chating_app/screens/list_member.dart';
import 'package:chating_app/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:chating_app/services/chat_api.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:chating_app/services/env_config.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:chating_app/widgets/full_screen_image.dart';

class ChatGroupProfileScreen extends StatefulWidget {
  final String chatId;
  final String userId;
  final ObjectUser user;


  const ChatGroupProfileScreen({super.key, required this.chatId, required this.userId, required this.user,});

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
      final membersResponse = await ChatApi.getGroupMembers(widget.chatId, widget.userId);
      final messages = await ChatApi.fetchMessages(widget.chatId, widget.userId);

      final infoResponse = await http.get(Uri.parse("${EnvConfig.baseUrl}/chat/${widget.chatId}/info?userId=${widget.userId}"));
      final infoData = jsonDecode(infoResponse.body);
      final chatData = infoData['data'];

      final currentUser = membersResponse.firstWhere(
            (m) => m['userId'].toString() == widget.userId,
        orElse: () => {},
      );
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
        members = membersResponse;
        groupName = chatData['chatName'] ?? 'Unnamed Group';
        groupDescription = chatData['description'] ?? '';
        groupImageUrl = chatData['imageUrl'] ?? '';
        imageUrls = images;
        fileMessages = files;
        linkMessages = links;
        isLoading = false;
      });
    } catch (e) {
      print("Lỗi khi load dữ liệu nhóm: $e");
    }
  }

  Future<void> _pickAndUploadGroupImage(String chatId) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final fileBytes = await pickedFile.readAsBytes();
      final fileName = pickedFile.name;

      // Bước 1: Upload ảnh lên server/S3 để lấy URL
      final imageUrl = await _uploadImageAndGetUrl(fileBytes, fileName);
      if (imageUrl == null) {
        print("Không lấy được URL ảnh sau khi upload");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lỗi khi tải ảnh lên server")),
        );
        return;
      }

      // Bước 2: Gửi {userId, image} tới endpoint cập nhật ảnh nhóm
      final updateUrl = Uri.parse("${EnvConfig.baseUrl}/group/$chatId/updateimage");
      final userId = int.tryParse(widget.userId) ?? 0;

      final body = jsonEncode({
        "userId": userId,
        "image": imageUrl,
      });

      try {
        final response = await http.post(
          updateUrl,
          headers: {"Content-Type": "application/json"},
          body: body,
        );

        final responseData = jsonDecode(response.body);

        if (response.statusCode == 200 && responseData["success"] == true) {
          print("Group photo update successful");
          setState(() {
            groupImageUrl = imageUrl;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Group photo update successful")),
          );
        } else {
          print("Image update error: ${response.body}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Lỗi: ${responseData['message']}")),
          );
        }
      } catch (e) {
        print("Exception khi gửi request: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi xảy ra: $e")),
        );
      }
    }
  }
  Future<String?> _uploadImageAndGetUrl(Uint8List fileBytes, String fileName) async {
    final uploadUrl = Uri.parse("${EnvConfig.baseUrl}/user/upload");

    var request = http.MultipartRequest("POST", uploadUrl);
    request.files.add(http.MultipartFile.fromBytes(
      "file",
      fileBytes,
      filename: fileName,
      contentType: MediaType("image", "jpeg"),
    ));

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);

      if (response.statusCode == 200 && data["imageUrl"] != null) {
        return data["imageUrl"];
      } else {
        print("Upload fail: $responseBody");
        return null;
      }
    } catch (e) {
      print("Exception when upload picture: $e");
      return null;
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
        const SnackBar(content: Text("Cannot open file. Make sure you have the correct application.")),
      );
    }
  }

  ///Hàm giải tán nhóm
  void _disbandGroup() async {
    print("Current role: $currentRole");

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
      try {
        await ChatApi.disbandGroup(widget.chatId, widget.userId);

        await Future.delayed(const Duration(milliseconds: 500)); // Delay nhẹ

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Group Dissolution Successful")),
        );

        await Future.delayed(const Duration(seconds: 1)); // Cho user thấy thông báo

        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => MainScreen(user: widget.user, )),
                (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Lỗi: ${e.toString()}")),
          );
        }
      }
    }
  }

  ///Hàm rời khỏi nhóm
  void _leaveGroup() async {
    final confirmed = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Leave Group"),
        content: const Text("Are you sure you want to leave this group?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Leave")),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ChatApi.leaveGroup(widget.chatId, widget.userId);

      await Future.delayed(const Duration(milliseconds: 500));

      bool leftGroup = false;

      try {
        final membersCheck = await ChatApi.getGroupMembers(widget.chatId, widget.userId);
        final exists = membersCheck.any((m) => m['userId'].toString() == widget.userId);
        leftGroup = !exists;
      } catch (e) {
        leftGroup = true;
      }

      if (leftGroup && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Left the group")),
        );
        await Future.delayed(const Duration(seconds: 1));
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => MainScreen(user: widget.user)),
                (route) => false,
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Not left group yet, try again later")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: ${e.toString()}")),
        );
      }
    }
  }

  ///Hàm edit tên, mô tả nhóm
  Future<void> _editGroupField(String field, String label, String currentValue) async {
    final controller = TextEditingController(text: currentValue);
    final newValue = await showDialog<String>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text("Edit $label"),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(hintText: "Input $label new"),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel")),
              TextButton(
                  onPressed: () => Navigator.pop(context, controller.text),
                  child: const Text("Save")),
            ],
          ),
    );

    if (newValue != null && newValue
        .trim()
        .isNotEmpty && newValue != currentValue) {
      if (field == 'name') {
        // Gọi API đổi tên nhóm trước
        try {
          await ChatApi.renameGroup(widget.chatId, widget.userId, newValue);
          setState(() {
            groupName = newValue;
          });
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Group rename error: $e")),
          );
        }
      } else if (field == 'description') {
        final response = await http.post(
          Uri.parse("${EnvConfig.baseUrl}/chat/update-info"),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "chatId": widget.chatId,
            "field": field,
            "value": newValue.trim(),
          }),
        );

        if (response.statusCode == 200) {
          setState(() {
            groupDescription = newValue;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Update fail: ${response.body}")),
          );
        }
      }
    }
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
            GestureDetector(
              onTap: isAdmin ? () => _pickAndUploadGroupImage(widget.chatId) : null,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    child: groupImageUrl != null && groupImageUrl!.isNotEmpty
                        ? null
                        : Icon(Icons.group),
                    backgroundImage: groupImageUrl != null && groupImageUrl!.isNotEmpty
                        ? NetworkImage(groupImageUrl!)
                        : null,
                  ),
                  if (isAdmin)
                    const Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.edit, size: 16, color: Colors.black),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            Text(groupName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(groupDescription, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("Change group name"),
              onTap: () => _editGroupField("name", "group name", groupName),
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text("Change description"),
              onTap: () => _editGroupField("description", "description group", groupDescription),
            ),
            if (isAdmin)
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text("Add new member"),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ListMemberScreen(
                        userId: widget.userId,
                        chatId: widget.chatId,
                      ),
                    ),
                  );

                  if (result == true) {
                    _loadData(); // reload lại dữ liệu nếu thêm thành viên thành công
                  }
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
            ...members.map((m) {
              final role = m['role'] ?? '';
              String roleText;
              switch (role) {
                case 'owner':
                  roleText = 'Trưởng nhóm';
                  break;
                case 'admin':
                  roleText = 'Phó nhóm';
                  break;
                default:
                  roleText = 'Thành viên';
              }

              return ListTile(
                leading: CircleAvatar(backgroundImage: NetworkImage(m['imageUrl'] ?? '')),
                title: Text(m['name'] ?? ''),
                subtitle: Text(roleText),
              );
            }),

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
                title: Text(url, style: const TextStyle(color: Colors.blue),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                onTap: () => openFileUrl(context, url),
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
                onTap: () => openFileUrl(context, url),
              );
            }),
          ],
        ),
      ),
    );
  }
}