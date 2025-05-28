import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:chating_app/services/env_config.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';


class CreateGroupScreen extends StatefulWidget {
  final String userId;
  final void Function()? onGroupCreated;
  //Tự tick chọn user đang chat 1-1 để tạo group
  final String? initialSelectedUserId;

  const CreateGroupScreen({super.key, required this.userId, this.onGroupCreated, this.initialSelectedUserId, });

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  List<Map<String, dynamic>> _searchResult = [];

  List<Map<String, dynamic>> _allFriends = [];
  final Map<String, bool> _selectedFriends = {}; // key là userId (String)
  String? _groupImageUrl;  // dùng để lưu URL ảnh nhóm sau khi upload

  @override
  void initState() {
    super.initState();
    _fetchFriends();
    _phoneController.addListener(() {
      final input = _phoneController.text.trim();
      if (input.isNotEmpty && input.length >= 3) {
        _searchPhone(input);
      } else {
        setState(() {
          _searchResult.clear();
        });
      }
    });
  }

  Future<void> _searchPhone(String phone) async {
    try {
      final response = await http.get(
          Uri.parse("${EnvConfig.baseUrl}/contact/find?phone=$phone&userId=${widget.userId}"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> users = data['data'];
          setState(() {
            _searchResult = users.map((u) => Map<String, dynamic>.from(u)).toList();
          });
        }
      }
    } catch (e) {
      print("Lỗi khi tìm theo số điện thoại: $e");
    }
  }


  Future<void> _fetchFriends() async {
    try {
      final response = await http.get(
        Uri.parse("${EnvConfig.baseUrl}/contact/list?userId=${widget.userId}"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawFriends = List<Map<String, dynamic>>.from(data['data']);

        // Lọc userId hợp lệ
        final friends = rawFriends.where((f) =>
        f['contactId'] != null &&
            f['contactId'].toString() != 'null' &&
            f['contactId'].toString() != 'undefined').toList();

        setState(() {
          _allFriends = friends;
          for (var friend in friends) {
            final id = friend['contactId'].toString();
            _selectedFriends[id] = false;
          }
          if (widget.initialSelectedUserId != null &&
              _selectedFriends.containsKey(widget.initialSelectedUserId)) {
            _selectedFriends[widget.initialSelectedUserId!] = true;
          }
        });
      }
    } catch (e) {
      print("Lỗi khi lấy danh sách bạn bè: $e");
    }
  }

  Future<void> _pickAndUploadGroupImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final url = Uri.parse("${EnvConfig.baseUrl}/user/upload");

      final fileBytes = await pickedFile.readAsBytes();
      final fileName = pickedFile.name;

      var request = http.MultipartRequest("POST", url);
      request.files.add(http.MultipartFile.fromBytes(
        "file",
        fileBytes,
        filename: fileName,
        contentType: MediaType("image", "jpeg"),
      ));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody);

        if (data['ok'] == 1) {
          setState(() {
            _groupImageUrl = data['imageUrl']; // lưu URL ảnh nhóm
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Group photo upload failed: ${data['message']}").tr()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Group photo upload failed (status): ${response.statusCode}").tr()),
        );
      }
    }
  }


  Future<void> createGroup() async {
    final name = _groupNameController.text.trim();
    final description = "";
    // final ownerId = widget.userId;
    final ownerId = int.tryParse(widget.userId);
    final image = "";

    final selectedIds = _selectedFriends.entries
        .where((e) => e.value == true)
        .map((e) => int.tryParse(e.key))
        .whereType<int>()
        .toList();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text("Invalid group name").tr()),
      );
      return;
    }

    if (selectedIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text("You need to select at least 2 members to create a group.").tr()),
      );
      return;
    }

    final url = Uri.parse("${EnvConfig.baseUrl}/group/create");
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      "name": name,
      "description": description,
      "image": _groupImageUrl ?? "",
      "ownerId": ownerId,
      "initialMembers": selectedIds,
    });

    print("Send group creation data:");
    print("Body: $body");

    try {
      final response = await http.post(url, headers: headers, body: body);
      final data = jsonDecode(response.body);

      print("Response from server:");
      print("Status: ${response.statusCode}");
      print("Body: ${response.body}");

      if (response.statusCode == 201 && data["success"] == true) {
        widget.onGroupCreated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Group created successfully").tr()),
        );
        Navigator.pop(context);
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Creating group fail").tr(),
            content: Text(data["message"] ?? "Đã xảy ra lỗi không xác định."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
            ],
          ),
        );
      }
    } catch (e) {
      print("Exception khi gọi API: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi kết nối: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text("Create Group").tr(),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              reverse: true,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                      child: Column(
                        // crossAxisAlignment: CrossAxisAlignment.stretch,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundImage: _groupImageUrl != null
                                    ? NetworkImage(_groupImageUrl!)
                                    : AssetImage('assets/images/default_group.png') as ImageProvider,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: InkWell(
                                  onTap: _pickAndUploadGroupImage,
                                  child: CircleAvatar(
                                    radius: 15,
                                    backgroundColor: Colors.white,
                                    child: Icon(Icons.edit, size: 18, color: Colors.blue),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _groupNameController,
                            decoration:  InputDecoration(
                              labelText: "Group name".tr(),
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.edit),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Text("VN (+84)", style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _phoneController,
                                  decoration:  InputDecoration(
                                    labelText: "Phone number".tr(),
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.phone,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (_searchResult.isNotEmpty) ...[
                            const Text(
                              "Search result...",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ).tr(),
                            const SizedBox(height: 8),
                            ..._searchResult.map((user) {
                              final id = user['userId'].toString();
                              final name = user['name'];
                              final phone = user['phone'];
                              final avatar = user['imageUrl'] ?? '';

                              return CheckboxListTile(
                                value: _selectedFriends[id] ?? false,
                                onChanged: (val) {
                                  setState(() {
                                    _selectedFriends[id] = val ?? false;
                                  });
                                },
                                title: Text(name),
                                subtitle: Text(phone),
                                secondary: avatar.isNotEmpty
                                    ? CircleAvatar(backgroundImage: NetworkImage(avatar))
                                    : CircleAvatar(child: Text(name[0])),
                              );
                            }),
                            const SizedBox(height: 16),
                          ],

                          const Text(
                            "List Friends",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ).tr(),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 350,
                            child: ListView(
                              shrinkWrap: true,
                              children: _allFriends.map((friend) {
                                final id = friend['contactId'].toString();
                                final name = friend['name'];
                                final phone = friend['phone'];
                                final avatar = friend['imageUrl'] ?? '';
                                return CheckboxListTile(
                                  value: _selectedFriends[id] ?? false,
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedFriends[id] = val ?? false;
                                    });
                                  },
                                  title: Text(name),
                                  subtitle: Text(phone),
                                  secondary: avatar.isNotEmpty
                                      ? CircleAvatar(backgroundImage: NetworkImage(avatar))
                                      : CircleAvatar(child: Text(name[0])),
                                );
                              }).toList(),
                            ),
                          ),

                          const Spacer(),
                          ElevatedButton(
                            onPressed: createGroup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              "Create Group",
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ).tr(),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: Colors.red),
                            ).tr(),
                          ),
                        ],
                      )
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}