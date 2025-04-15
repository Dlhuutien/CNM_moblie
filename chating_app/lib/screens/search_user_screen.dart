import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart'; // Thêm import FirebaseAuth

class SearchUserScreen extends StatefulWidget {
  @override
  _SearchUserScreenState createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  String? currentUserID;

  @override
  void initState() {
    super.initState();
    _getCurrentUserID();
  }

  Future<void> _getCurrentUserID() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Gọi API để lấy user ID nội bộ từ email/số điện thoại (nếu cần)
      try {
        final response = await http.get(Uri.parse("http://138.2.106.32/user/account?phone=${user.phoneNumber}"));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data != null && data.length > 0) {
            setState(() {
              currentUserID = data[0]['id'].toString();
            });
          }
        }
      } catch (e) {
        print("Lỗi lấy userID: $e");
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _searchUser() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse("http://138.2.106.32/user/account?phone=$phone"));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data.length > 0) {
          _showUserDialog(data[0]);
        } else {
          _showMessage("Không tìm thấy người dùng");
        }
      } else {
        _showMessage("Lỗi khi tìm kiếm");
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
            if (user['image'] != null)
              CircleAvatar(radius: 40, backgroundImage: NetworkImage(user['image'])),
            SizedBox(height: 10),
            Text("Tên: ${user['name']}"),
            Text("SĐT: ${user['phone']}"),
            Text("Email: ${user['email']}"),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _sendFriendRequest(user['id']);
                Navigator.pop(context);
              },
              child: Text("Kết bạn"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Đóng"),
          ),
        ],
      ),
    );
  }

  Future<void> _sendFriendRequest(int receiverId) async {
    if (currentUserID == null) {
      _showMessage("Không xác định được người gửi");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("https://your-api-url.com/friend/request"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "senderId": int.parse(currentUserID!),
          "receiverId": receiverId,
        }),
      );

      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        _showMessage(res['message'] ?? "Đã gửi lời mời kết bạn");
      } else {
        _showMessage("Không thể gửi lời mời");
      }
    } catch (e) {
      _showMessage("Lỗi khi gửi lời mời: $e");
    }
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
                : ElevatedButton(
              onPressed: _searchUser,
              child: Text("Tìm kiếm"),
            ),
          ],
        ),
      ),
    );
  }
}
