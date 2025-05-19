import 'package:chating_app/data/user.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chating_app/services/env_config.dart';

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
  List<Map<String, dynamic>> searchResult = [];
  String _input = "";

  @override
  void initState() {
    super.initState();
    currentUserID = widget.user.userID;
    _loadSearchHistory();
    _phoneController.addListener(() {
      final input = _phoneController.text.trim();
      setState(() => _input = input);
      if (input.isEmpty) {
        _loadSearchHistory();
        setState(() => searchResult.clear());
      } else if (input.length > 0) { //Nhập 1 chữ số sẽ tìm
        _searchUser();
      }
    });
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getStringList('searchHistory') ?? [];
    setState(() {
      searchHistory = savedData.map((item) => json.decode(item)).toList().cast<Map<String, dynamic>>();
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

    setState(() {
      _isLoading = true;
      searchResult.clear();
    });

    try {
      final response = await http.get(
        Uri.parse("${EnvConfig.baseUrl}/contact/find?phone=$phone&userId=$currentUserID"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final List<dynamic> users = data['data'];

          if (phone.length == 10 && users.isNotEmpty) {
            searchResult.add(Map<String, dynamic>.from(users.first));
          } else {
            searchResult = users.map((u) => Map<String, dynamic>.from(u)).toList();
          }

          if (phone.length == 10 && users.isNotEmpty) {
            final userMap = Map<String, dynamic>.from(users.first);
            // Tránh thêm trùng
            if (!searchResult.any((u) => u['phone'] == userMap['phone'])) {
              searchResult.add(userMap);
            }
          } else {
            searchResult = users.map((u) => Map<String, dynamic>.from(u)).toList();
          }

          setState(() {});
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

  void _showUserDialog(Map<String, dynamic> user) async {
    searchHistory.removeWhere((item) => item['phone'] == user['phone']);
    searchHistory.insert(0, Map<String, dynamic>.from(user));
    await _saveSearchHistory();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "User Found",
      barrierColor: Colors.black54,
      transitionDuration: Duration.zero,
      transitionBuilder: (context, animation, secondaryAnimation, child) => child,
      pageBuilder: (context, anim1, anim2) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Center(
            child: Text(
              "User Found",
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          content: StatefulBuilder(
            builder: (context, setStateDialog) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (user['imageUrl'] != null)
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(user['imageUrl']),
                  ),
                const SizedBox(height: 10),
                Text("Name: ${user['name']}"),
                Text("Phone: ${user['phone']}"),
                Text("Email: ${user['email']}"),
                const SizedBox(height: 16),
                if (user['friend'] == true)
                  const Text("Already friends", style: TextStyle(color: Colors.green))
                else if (user['friendRequestSent'] == true)
                  const Text("Friend request sent", style: TextStyle(color: Colors.orange))
                else
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _sendFriendRequest(user['userId']);
                      setStateDialog(() {
                        user['friendRequestSent'] = true;
                      });
                    },
                    icon: const Icon(Icons.person_add, color: Colors.white),
                    label: const Text(
                      "Add Friend",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _phoneController.clear();
              },
              child: const Text("Close", style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendFriendRequest(int contactId) async {
    try {
      final response = await http.post(
        Uri.parse("${EnvConfig.baseUrl}/contact/add?userId=$currentUserID&contactId=$contactId"),
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

  Widget _buildUserTile(Map<String, dynamic> user, int index) {
    return Card(
      child: ListTile(
        leading: user['imageUrl'] != null
            ? CircleAvatar(backgroundImage: NetworkImage(user['imageUrl']))
            : const CircleAvatar(child: Icon(Icons.person)),
        title: Text(user['name'] ?? 'Không tên'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("SĐT: ${user['phone']}"),
            Text("Email: ${user['email'] ?? "-"}"),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.person_add_alt_1, color: Colors.blue),
              onPressed: () => _showUserDialog(user),
            ),
            if (_input.isEmpty)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteHistoryAt(index),
              ),
          ],
        ),
        onTap: () => _showUserDialog(user),
      ),
    );
  }

  Widget _buildHistoryList() {
    if (searchHistory.isEmpty) {
      return const Center(child: Text("Chưa có lịch sử tìm kiếm"));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Lịch sử tìm kiếm", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: searchHistory.length,
            itemBuilder: (context, index) => _buildUserTile(searchHistory[index], index),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultList() {
    if (searchResult.isEmpty) {
      return const Center(child: Text("Không tìm thấy người dùng."));
    }
    return ListView.builder(
      itemCount: searchResult.length,
      itemBuilder: (context, index) => _buildUserTile(searchResult[index], index),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          "Tìm kiếm người dùng",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: "Nhập số điện thoại",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const CircularProgressIndicator()
                : Expanded(
              child: _input.isEmpty
                  ? _buildHistoryList()
                  : _buildSearchResultList(),
            ),
          ],
        ),
      ),
    );
  }
}
