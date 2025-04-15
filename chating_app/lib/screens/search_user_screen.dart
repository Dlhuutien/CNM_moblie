import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chating_app/data/user.dart';

class SearchUserScreen extends StatefulWidget {
  final ObjectUser user;

  const SearchUserScreen({super.key, required this.user});

  @override
  _SearchUserScreenState createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  late String currentUserID;
  List<Map<String, dynamic>> searchHistory = [];

  @override
  void initState() {
    super.initState();
    currentUserID = widget.user.userID;
    _loadSearchHistory();
    _phoneController.addListener(() {
      final input = _phoneController.text.trim();
      if (input.length == 10 && RegExp(r'^\d{10}$').hasMatch(input)) {
        _searchUser();
      }
    });
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getStringList('searchHistory') ?? [];
    setState(() {
      searchHistory = savedData
          .map((item) => json.decode(item))
          .toList()
          .cast<Map<String, dynamic>>();
    });
  }

  Future<void> _saveSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = searchHistory.map((item) => json.encode(item)).toList();
    await prefs.setStringList('searchHistory', encoded);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _searchUser() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse("http://138.2.106.32/contact/find?phone=$phone&userId=$currentUserID"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final List<dynamic> users = data['data'];
          for (var user in users) {
            searchHistory.removeWhere((item) => item['phone'] == user['phone']);
            searchHistory.insert(0, Map<String, dynamic>.from(user));
          }
          await _saveSearchHistory();
          if (users.isNotEmpty) _showUserDialog(users[0]);
        }
      } else {
        _showMessage("Không tìm thấy người dùng.");
      }
    } catch (e) {
      _showMessage("Lỗi: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showUserDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Người dùng tìm thấy"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (user['imageUrl'] != null)
              CircleAvatar(radius: 40, backgroundImage: NetworkImage(user['imageUrl'])),
            SizedBox(height: 10),
            Text("Tên: ${user['name']}"),
            Text("SĐT: ${user['phone']}"),
            Text("Email: ${user['email']}"),
            SizedBox(height: 16),
            if (!user['friend'] && !user['friendRequestSent'])
              ElevatedButton(
                onPressed: () async {
                  await _sendFriendRequest(user['userId']);
                  Navigator.of(context).pop();
                  _phoneController.clear();
                },
                child: Text("Kết bạn"),
              )
            else if (user['friend'])
              Text("Đã là bạn bè", style: TextStyle(color: Colors.green))
            else if (user['friendRequestSent'])
                Text("Đã gửi lời mời", style: TextStyle(color: Colors.orange)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _phoneController.clear();
            },
            child: Text("Đóng"),
          ),
        ],
      ),
    );
  }

  Future<void> _sendFriendRequest(int contactId) async {
    try {
      final response = await http.post(
        Uri.parse("http://138.2.106.32/contact/add?userId=$currentUserID&contactId=$contactId"),
      );
      final res = json.decode(response.body);
      _showMessage(res['message'] ?? "Đã gửi lời mời kết bạn");
    } catch (e) {
      _showMessage("Lỗi khi gửi lời mời: $e");
    }
  }

  Future<void> _deleteHistoryAt(int index) async {
    setState(() {
      searchHistory.removeAt(index);
    });
    await _saveSearchHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tìm kiếm người dùng")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: "Nhập số điện thoại",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16),
            _isLoading
                ? CircularProgressIndicator()
                : Expanded(
              child: searchHistory.isEmpty
                  ? Center(child: Text("Chưa có lịch sử tìm kiếm"))
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Lịch sử tìm kiếm",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: searchHistory.length,
                      itemBuilder: (context, index) {
                        final user = searchHistory[index];
                        return Card(
                          child: ListTile(
                            leading: user['imageUrl'] != null
                                ? CircleAvatar(backgroundImage: NetworkImage(user['imageUrl']))
                                : CircleAvatar(child: Icon(Icons.person)),
                            title: Text(user['name'] ?? 'Không tên'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("SĐT: ${user['phone']}"),
                                Text("Email: ${user['email'] ?? "-"}"),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _deleteHistoryAt(index);
                              },
                            ),
                            onTap: () => _showUserDialog(user),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}