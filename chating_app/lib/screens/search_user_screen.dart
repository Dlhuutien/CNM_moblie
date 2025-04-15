import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
<<<<<<< Updated upstream
import 'package:shared_preferences/shared_preferences.dart';
=======

>>>>>>> Stashed changes

class SearchUserScreen extends StatefulWidget {
  @override
  _SearchUserScreenState createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
<<<<<<< Updated upstream
  int currentUserID = 4285; // TODO: Lấy ID từ Auth/Provider
  List<Map<String, dynamic>> searchHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _phoneController.addListener(() {
      if (_phoneController.text.trim().length >= 9) {
        _searchUser(); // Auto search
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
=======
  int currentUserID = 1007; // TODO: Lấy ID từ Auth/Provider
>>>>>>> Stashed changes

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _searchUser() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

<<<<<<< Updated upstream
    // Kiểm tra xem số điện thoại có trong lịch sử không
    final index = searchHistory.indexWhere((item) => item['phone'] == phone);
    if (index != -1) { // Nếu đã có trong lịch sử, hiển thị dialog
      final existingUser = searchHistory[index];
      _showUserDialog(existingUser);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse("http://138.2.106.32/user/account?phone=$phone"),
=======
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
          Uri.parse("http://138.2.106.32/user/account?phone=$phone")
>>>>>>> Stashed changes
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
<<<<<<< Updated upstream
        if (data != null && data.isNotEmpty) {
          final user = data[0];

          // Nếu đã có user cũ thì xoá để đưa lên đầu
          searchHistory.removeWhere((item) => item['phone'] == user['phone']);
          searchHistory.insert(0, {
            "name": user['name'],
            "email": user['email'],
            "phone": user['phone'],
            "image": user['image'],
            "id": user['id'],
          });
          await _saveSearchHistory();

          _showUserDialog(user);
=======
        if (data != null && data.length > 0) {
          _showUserDialog(data[0]);
        } else {
          _showMessage("Không tìm thấy người dùng");
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
                Navigator.of(context, rootNavigator: true).pop();
                _phoneController.clear(); // Clear ô nhập
=======
                Navigator.pop(context);
>>>>>>> Stashed changes
              },
              child: Text("Kết bạn"),
            ),
          ],
        ),
        actions: [
          TextButton(
<<<<<<< Updated upstream
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              _phoneController.clear(); // Clear ô nhập khi đóng dialog
            },
=======
            onPressed: () => Navigator.pop(context),
>>>>>>> Stashed changes
            child: Text("Đóng"),
          ),
        ],
      ),
    );
  }

  Future<void> _sendFriendRequest(int receiverId) async {
    try {
      final response = await http.post(
<<<<<<< Updated upstream
        Uri.parse("http://138.2.106.32/friend/request"),
=======
        Uri.parse("https://your-api-url.com/friend/request"),
>>>>>>> Stashed changes
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "senderId": currentUserID,
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

<<<<<<< Updated upstream
  Future<void> _deleteHistoryAt(int index) async {
    setState(() {
      searchHistory.removeAt(index);
    });
    await _saveSearchHistory();
  }

=======
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
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
                            leading: user['image'] != null
                                ? CircleAvatar(backgroundImage: NetworkImage(user['image']))
                                : CircleAvatar(child: Icon(Icons.person)),
                            title: Text(user['name'] ?? 'Không tên'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("SĐT: ${user['phone']}"),
                                Text("Email: ${user['email']}"),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _deleteHistoryAt(index);
                              },
                            ),
                            onTap: () {
                              _showUserDialog(user);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
=======
                : ElevatedButton(
              onPressed: _searchUser,
              child: Text("Tìm kiếm"),
>>>>>>> Stashed changes
            ),
          ],
        ),
      ),
    );
  }
}
