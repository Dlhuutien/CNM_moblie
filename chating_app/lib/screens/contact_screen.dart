import 'dart:async';
import 'package:chating_app/screens/create_group_screen.dart';
import 'package:chating_app/services/chat_api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:chating_app/data/user.dart';
import 'package:chating_app/screens/chat_detail_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:chating_app/services/env_config.dart';

class ContactScreen extends StatelessWidget {
  final ObjectUser user;
  const ContactScreen({super.key, required this.user});


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Friend List'),
              Tab(text: 'Your Group'),
              Tab(text: 'Notification'),
            ],
            labelColor: Colors.white, // Màu chữ tab đang được chọn
            unselectedLabelColor: Colors.black87, // Màu chữ tab không được chọn
            indicator: BoxDecoration(
              color: Colors.blue, // Nền xanh cho tab đang được chọn
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          ),
        ),
        body: TabBarView(
          children: [
            FriendList(user: user),
            GroupList(user: user),
            NotificationList(userId: user.userID),
          ],
        ),
      ),
    );
  }
}

class FriendList extends StatefulWidget {
  final ObjectUser user;
  const FriendList({super.key, required this.user});

  @override
  State<FriendList> createState() => _FriendListState();
}

class _FriendListState extends State<FriendList> {
  Map<String, List<Map<String, dynamic>>> groupedFriends = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  /// Gọi API để lấy danh sách bạn bè, sắp xếp theo tên và nhóm theo chữ cái đầu
  Future<void> _fetchFriends() async {
    setState(() => isLoading = true);
    final response = await http.get(Uri.parse(
        "${EnvConfig.baseUrl}/contact/list?userId=${widget.user.userID}"));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<Map<String, dynamic>> sorted = List<Map<String, dynamic>>.from(
          data['data']);

      sorted.sort((a, b) {
        final nameA = (a['name'] ?? '').toLowerCase();
        final nameB = (b['name'] ?? '').toLowerCase();
        return nameA.compareTo(nameB);
      });

      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (var friend in sorted) {
        final name = friend['name'] ?? '';
        final letter = name.isNotEmpty ? name[0].toUpperCase() : '#';
        grouped.putIfAbsent(letter, () => []).add(friend);
      }

      setState(() {
        groupedFriends = grouped;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  ///Xóa bạn bè
  Future<void> _unfriend(String contactId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc chắn muốn xóa bạn này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ChatApi.unfriendContact(widget.user.userID,contactId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa bạn thành công')),
        );
        await _fetchFriends(); // load lại danh sách bạn bè sau khi xóa
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa bạn thất bại')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    if (groupedFriends.isEmpty)
      return const Center(child: Text("Chưa có bạn bè nào"));

    final sortedKeys = groupedFriends.keys.toList()
      ..sort();

    return ListView.builder(
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final letter = sortedKeys[index];
        final friends = groupedFriends[letter]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 4.0, horizontal: 12),
              child: Text(letter, style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ...friends.map((friend) {
              return ListTile(
                leading: (friend['imageUrl'] != null && friend['imageUrl'].toString().isNotEmpty)
                    ? CircleAvatar(
                  backgroundImage: NetworkImage(friend['imageUrl']),
                )
                    : const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(friend['name'] ?? 'Không tên'),
                subtitle: Text(friend['phone'] ?? 'Không có số điện thoại'),
                trailing: SizedBox(
                  width: 150,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.message),
                        onPressed: () {
                          final chatId = [
                            widget.user.userID,
                            friend['contactId']
                          ]
                              .map((e) => e.toString())
                              .toList()
                            ..sort();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ChatDetailScreen(
                                    name: friend['name'],
                                    chatId: chatId.join('-'),
                                    user: widget.user,
                                    userId: widget.user.userID,
                                  ),
                            ),
                          );
                        },
                      ),
                      IconButton(icon: const Icon(Icons.call),
                          onPressed: () {}),
                      IconButton(icon: const Icon(
                          Icons.delete, color: Colors.red), onPressed: () {
                        _unfriend(friend['contactId'].toString());
                      },),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}

class NotificationList extends StatefulWidget {
  final String userId;
  const NotificationList({super.key, required this.userId});

  @override
  State<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {
  List<dynamic> requests = [];

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  /// Gọi API lấy danh sách lời mời kết bạn
  Future<void> _fetchRequests() async {
    final response = await http.get(Uri.parse("${EnvConfig.baseUrl}/contact/requests?userId=${widget.userId}"));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        requests = data['data'];
      });
    }
  }

  /// Gửi yêu cầu chấp nhận lời mời kết bạn
  Future<void> _acceptRequest(String senderId) async {
    final response = await http.post(
      Uri.parse("${EnvConfig.baseUrl}/contact/accept?userId=${widget.userId}&senderId=$senderId"),
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã chấp nhận")));
      _fetchRequests();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) return const Center(child: Text("Không có lời mời kết bạn"));

    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return ListTile(
          leading: CircleAvatar(
            child: request['senderImage'] != null && request['senderImage'].toString().isNotEmpty ? null : const Icon(Icons.person),
            backgroundImage: (request['senderImage'] != null && request['senderImage'].toString().isNotEmpty)
                ? NetworkImage(request['senderImage'])
                : null,
          ),
          title: Text(request['senderName']),
          subtitle: Text("SĐT: ${request['senderPhone']}"),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: () => _acceptRequest(request['senderId']),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () {},
              ),
            ],
          ),
        );
      },
    );
  }
}

class GroupList extends StatefulWidget {
  final ObjectUser user;
  const GroupList({super.key, required this.user});

  @override
  State<GroupList> createState() => _GroupListState();
}

class _GroupListState extends State<GroupList> {
  Map<String, List<Map<String, dynamic>>> groupedGroups = {};
  bool isLoading = true;
  Timer? _groupRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadGroups();
    _groupRefreshTimer = Timer.periodic(Duration(seconds: 15), (_) => _loadGroups());
  }

  @override
  void dispose() {
    _groupRefreshTimer?.cancel();
    super.dispose();
  }

  /// Gọi API lấy danh sách các nhóm của người dùng, lọc các nhóm chưa bị giải tán,
  /// sắp xếp theo tên và nhóm theo chữ cái đầu.
  /// Tự động cập nhật khi có thay đổi để hiển thị thời gian thực.
  Future<void> _loadGroups() async {
    try {
      final chats = await ChatApi.fetchChatsWithLatestMessage(widget.user.userID);
      final filtered = chats
          .where((chat) =>
      chat["ChatID"].toString().startsWith("group-") &&
          chat["Status"] != "disbanded")
          .toList();

      filtered.sort((a, b) {
        final nameA = (a["chatName"] ?? "").toString().toLowerCase();
        final nameB = (b["chatName"] ?? "").toString().toLowerCase();
        return nameA.compareTo(nameB);
      });

      final grouped = <String, List<Map<String, dynamic>>>{};
      for (var group in filtered) {
        final name = group["chatName"] ?? "Unnamed Group";
        final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : "#";
        grouped.putIfAbsent(firstLetter, () => []).add(group);
      }

      //️ Chỉ update nếu có thay đổi
      if (!mapEquals(grouped, groupedGroups)) {
        setState(() {
          groupedGroups = grouped;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Lỗi khi load nhóm: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedKeys = groupedGroups.keys.toList()..sort();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateGroupScreen(userId: widget.user.userID, onGroupCreated: _loadGroups,)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: Colors.blue),
            ),
            child: const Text('Create new group', style: TextStyle(color: Colors.blue)),
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : groupedGroups.isEmpty
              ? const Center(child: Text("Không có nhóm nào"))
              : ListView.builder(
            itemCount: sortedKeys.length,
            itemBuilder: (context, index) {
              final letter = sortedKeys[index];
              final groups = groupedGroups[letter]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12),
                    child: Text(letter, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  ...groups.map((group) {
                    final name = group["chatName"] ?? "Unnamed Group";
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundImage: group["imageUrl"] != null && group["imageUrl"].toString().isNotEmpty
                            ? NetworkImage(group["imageUrl"])
                            : const AssetImage('assets/group_default.png') as ImageProvider,
                      ),
                      title: Text(name),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatDetailScreen(
                              name: name,
                              chatId: group["ChatID"],
                              userId: widget.user.userID,
                              user: widget.user,
                              isGroup: true,
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
