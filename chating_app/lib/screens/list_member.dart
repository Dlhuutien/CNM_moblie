import 'package:chating_app/data/user.dart';
import 'package:chating_app/screens/chat_detail_screen.dart';
import 'package:chating_app/services/chat_api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:chating_app/services/env_config.dart';

class ListMemberScreen extends StatefulWidget {
  final String userId;
  final String chatId;
  final int initialTabIndex; // 0: Add Members, 1: Members

  const ListMemberScreen({
    super.key,
    required this.userId,
    required this.chatId,
    this.initialTabIndex = 0,
  });

  @override
  State<ListMemberScreen> createState() => _ListMemberScreenState();
}

class _ListMemberScreenState extends State<ListMemberScreen> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _friendsNotInGroup = [];
  List<Map<String, dynamic>> _groupMembers = [];
  final Map<String, bool> _selectedFriends = {};
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredList = [];
  bool _isMember = false;
  bool _dataLoaded = false;
  List<Map<String, dynamic>> _searchResult = [];

  ///Hàm lấy role user
  String getCurrentUserRole() {
    final me = _groupMembers.firstWhere(
          (m) => m['userId'].toString() == widget.userId,
      orElse: () => {},
    );
    return me['role'] ?? 'member';
  }


  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  ///Hàm chức năng tìm kiếm user
  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.length >= 3 && RegExp(r'^\d+$').hasMatch(query)) {
      _searchByPhone(query); // gọi tìm theo số điện thoại
    } else {
      setState(() {
        final listToFilter = _isMember ? _groupMembers : _friendsNotInGroup;
        _filteredList = listToFilter.where((item) {
          final name = item['name']?.toLowerCase() ?? '';
          final phone = item['phone']?.toLowerCase() ?? '';
          return name.contains(query.toLowerCase()) || phone.contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  Future<void> _searchByPhone(String phone) async {
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
        } else {
          setState(() {
            _searchResult.clear();
          });
        }
      } else {
        print("Searching Error: ${response.body}");
      }
    } catch (e) {
      print("Lỗi khi tìm theo số điện thoại: $e");
    }
  }



  Future<void> _loadData() async {
    try {
      final rawFriends = await ChatApi.getContacts(widget.userId);
      final members = await ChatApi.getGroupMembers(widget.chatId, widget.userId);
      final memberIds = members.map((m) => m['userId'].toString()).toSet();

      final notInGroup = rawFriends.where((f) => !memberIds.contains(f['contactId'].toString())).toList();

      final role = members.firstWhere(
            (m) => m['userId'].toString() == widget.userId,
        orElse: () => {},
      )['role'] ?? 'unknown';

      setState(() {
        _friendsNotInGroup = notInGroup;
        _filteredList = notInGroup;
        _isMember = role == 'member';
        _dataLoaded = true;

        final friendIds = rawFriends.map((f) => f['contactId'].toString()).toSet();
        _groupMembers = members.map((m) {
          final userId = m['userId'].toString();
          return {
            ...m,
            'isFriend': friendIds.contains(userId),
          };
        }).toList();

        for (var friend in notInGroup) {
          final id = friend['contactId'].toString();
          _selectedFriends[id] = false;
        }
      });
    } catch (e) {
      print("Lỗi khi load danh sách: $e");
    }
  }

  ///Hàm thêm thành viên vào nhóm
  Future<void> _addMembersToGroup() async {
    final selectedIds = _selectedFriends.entries
        .where((e) => e.value)
        .map((e) => int.tryParse(e.key))
        .whereType<int>()
        .toList();

    if (selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least 1 member")),
      );
      return;
    }

    bool hasError = false;

    for (var memberId in selectedIds) {
      try {
        await ChatApi.addGroupMember(widget.chatId, widget.userId, memberId);
      } catch (e) {
        print("Lỗi khi thêm thành viên $memberId: $e");
        hasError = true;
      }
    }

    if (!hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Add member successfully!")),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Some members can not join in.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_dataLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final tabCount = _isMember ? 1 : 2;

    return DefaultTabController(
      length: tabCount,
      initialIndex: _isMember ? 0 : widget.initialTabIndex,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          title: const Text("Group Members"),
          bottom: TabBar(
            labelColor: Colors.white,
            indicatorColor: Colors.white,
            tabs: _isMember
                ? const [Tab(text: "Members")]
                : const [
              Tab(text: "Add Members"),
              Tab(text: "Members"),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: "Search",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: _isMember
                    ? [_buildMemberListTab()]
                    : [
                  _buildAddMemberTab(),
                  _buildMemberListTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMemberTab() {
    final query = _searchController.text.toLowerCase();

    final filtered = query.isEmpty
        ? _friendsNotInGroup
        : _friendsNotInGroup.where((friend) {
      final name = friend['name']?.toLowerCase() ?? '';
      return name.contains(query);
    }).toList();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  if (_searchResult.isNotEmpty)
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
                            if (!_friendsNotInGroup.any((f) =>
                            f['contactId'].toString() == id)) {
                              _friendsNotInGroup.add({
                                'contactId': id,
                                'name': name,
                                'phone': phone,
                                'imageUrl': avatar,
                              });
                            }
                          });
                        },
                        title: Text(name),
                        subtitle: Text(phone),
                        secondary: avatar.isNotEmpty
                            ? CircleAvatar(backgroundImage: NetworkImage(
                            avatar))
                            : CircleAvatar(child: Text(name[0])),
                      );
                    }),
                  ...filtered.map((friend) {
                    final id = friend['contactId'].toString();
                    final name = friend['name'] ?? '';
                    final phone = friend['phone'] ?? '';
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
                      secondary: CircleAvatar(
                        backgroundImage: avatar.isNotEmpty ? NetworkImage(
                            avatar) : null,
                        child: avatar.isEmpty ? Text(
                            name.isNotEmpty ? name[0] : '?') : null,
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _addMembersToGroup,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text(
              "Add Selected Members", style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
  Widget _buildMemberListTab() {
    final query = _searchController.text.toLowerCase();

    final filtered = query.isEmpty
        ? _groupMembers
        : _groupMembers.where((member) {
      final name = member['name']?.toLowerCase() ?? '';
      final phone = member['phone']?.toLowerCase() ?? '';
      return name.contains(query) || phone.contains(query);
    }).toList();

    return ListView(
      children: filtered.map((member) {
        final isMe = member['userId'].toString() == widget.userId;
        final name = isMe ? 'Me' : member['name'] ?? '';
        final avatar = member['imageUrl'] ?? '';
        final role = member['role'] ?? '';

        String roleText;
        switch (role) {
          case 'owner':
            roleText = 'owner';
            break;
          case 'admin':
            roleText = 'admin';
            break;
          default:
            roleText = 'members';
        }

        return ListTile(
          //Nếu là "Tôi" thì khôg hiện showInfo
          onTap: isMe ? null : () => _showMemberInfo(context, member),
          title: Text(name),
          subtitle: Text(roleText),
          leading: CircleAvatar(
            backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
            child: avatar.isEmpty ? Text(name.isNotEmpty ? name[0] : '?') : null,
          ),
          trailing: _buildTrailing(member),
        );
      }).toList(),
    );
  }

  ///Hiển thị thông tin khi nhấn vào thành viên
  void _showMemberInfo(BuildContext context, Map<String, dynamic> member) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(member['imageUrl'] ?? ''),
                ),
                title: Text(member['name'] ?? ''),
                subtitle: Text(member['role'] ?? ''),
                trailing: member['isFriend'] == true
                    ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.message),
                      onPressed: () {
                        final contactId = member['userId'].toString();
                        final chatId = [widget.userId, contactId]..sort();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatDetailScreen(
                              name: member['name'] ?? '',
                              chatId: chatId.join('-'),
                              userId: widget.userId,
                              user: member.containsKey('user')
                                  ? member['user']
                                  : ObjectUser.empty(),
                              isGroup: false,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                )
                    : null,
              ),
              const Divider(),
              if (getCurrentUserRole() == 'owner' && member['role'] == 'member') ...[
                ListTile(
                  title: const Text("Appointed as deputy group leader"),
                  onTap: () async {
                    Navigator.pop(context);
                    await ChatApi.changeGroupRole(
                      widget.chatId,
                      widget.userId,
                      member['userId'].toString(),
                      'admin',
                    );
                    await _loadData(); // cập nhật lại danh sách
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Appointed as deputy group leader")),
                    );
                  },
                ),
                ListTile(
                  title: const Text("Banned members"),
                  onTap: () {
                    Navigator.pop(context);
                    // gọi API chặn thành viên
                  },
                ),
                ListTile(
                  title: const Text("Remove from group", style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
                    await ChatApi.removeGroupMember(
                      widget.chatId,
                      widget.userId,
                      member['userId'].toString(),
                    );
                    await _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Delete members successfully")),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  ///Hiển thị nút kết bạn
  Widget? _buildTrailing(Map<String, dynamic> member) {
    final isFriend = member['isFriend'] == true;
    if (member['userId'].toString() == widget.userId) return const SizedBox();

    return isFriend
        ? null
        : ElevatedButton(
      onPressed: () {
        // gọi API kết bạn
      },
      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
      child: const Text("Add friend", style: TextStyle(color: Colors.white)),
    );
  }
}
