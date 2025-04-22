import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  List<Map<String, dynamic>> _allFriends = [];
  final Map<String, bool> _selectedFriends = {}; // key là userId (String)

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  Future<void> _fetchFriends() async {
    try {
      final response = await http.get(
        Uri.parse("http://138.2.106.32/contact/list?userId=${widget.userId}"),
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
        const SnackBar(content: Text("Group name không hợp lệ")),
      );
      return;
    }

    if (selectedIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cần chọn ít nhất 2 thành viên để tạo nhóm")),
      );
      return;
    }

    final url = Uri.parse("http://138.2.106.32/group/create");
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      "name": name,
      "description": description,
      "image": image,
      "ownerId": ownerId,
      "initialMembers": selectedIds,
    });

    print("Gửi dữ liệu tạo nhóm:");
    print("Body: $body");

    try {
      final response = await http.post(url, headers: headers, body: body);
      final data = jsonDecode(response.body);

      print("Phản hồi từ server:");
      print("Status: ${response.statusCode}");
      print("Body: ${response.body}");

      if (response.statusCode == 201 && data["success"] == true) {
        widget.onGroupCreated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Group created successfully")),
        );
        Navigator.pop(context);
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Tạo nhóm thất bại"),
            content: Text(data["message"] ?? "Đã xảy ra lỗi không xác định."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Đóng")),
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
        title: const Text("Create Group"),
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          child: Icon(Icons.group, size: 40),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _groupNameController,
                          decoration: const InputDecoration(
                            labelText: "Group name",
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
                                decoration: const InputDecoration(
                                  labelText: "Phone number",
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Friends List",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
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
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
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