import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreateGroupScreen extends StatefulWidget {
  final String userId;
  const CreateGroupScreen({super.key, required this.userId});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  List<Map<String, dynamic>> _allFriends = [];
  final Map<String, bool> _selectedFriends = {};

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  Future<void> _fetchFriends() async {
    try {
      final response = await http.get(Uri.parse("http://138.2.106.32/contact/list?userId=${widget.userId}"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final friends = List<Map<String, dynamic>>.from(data['data']);

        setState(() {
          _allFriends = friends;
          for (var friend in friends) {
            _selectedFriends[friend['name']] = false;
          }
        });
      }
    } catch (e) {
      print("Lỗi khi lấy danh sách bạn bè: $e");
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
                              final name = friend['name'];
                              final phone = friend['phone'];
                              final avatar = friend['imageUrl'] ?? '';
                              return CheckboxListTile(
                                value: _selectedFriends[name] ?? false,
                                onChanged: (val) {
                                  setState(() {
                                    _selectedFriends[name] = val ?? false;
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
                        const Spacer(), // Đẩy nút xuống đáy
                        ElevatedButton(
                          onPressed: () {
                            // TODO: Handle create group logic
                            Navigator.pop(context);
                          },
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
