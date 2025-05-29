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
import 'package:easy_localization/easy_localization.dart';
import 'package:chating_app/screens/friend_detail_screen.dart';
import 'package:chating_app/services/friend_service.dart';

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
          backgroundColor: Theme.of(context).colorScheme.background,
          bottom: TabBar(
            tabs:  [
              Tab(text: 'Friend List'.tr()),
              Tab(text: 'Your Group'.tr()),
              Tab(text: 'Notification'.tr()),
            ],
            labelColor: Colors.white, // chữ tab đang chọn
            //Chỉnh màu cho theme
            unselectedLabelColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade400
                : Colors.grey.shade700, // chữ tab chưa chọn
            indicator: BoxDecoration(
              color: Colors.blue, // nền cho tab được chọn
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
    try {
      final grouped = await FriendService.getGroupedFriends(widget.user.userID);
      setState(() {
        groupedFriends = grouped;
      });
    } catch (e) {
      print("Lỗi khi lấy danh sách bạn bè: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  ///Xóa bạn bè
  Future<void> _unfriend(String contactId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm').tr(),
        content: const Text('Are you sure you want to delete this friend?').tr(),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel').tr(),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)).tr(),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await FriendService.unfriendContact(widget.user.userID,contactId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Deleted friend successfully').tr()),
        );
        await _fetchFriends(); // load lại danh sách bạn bè sau khi xóa
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Deleted friend fail').tr()),
        );
      }
    }
  }

  Future<void> openFriendDetail(Map<String, dynamic> friend) async {
    final phone = friend['phone'];
    if (phone != null && phone.toString().isNotEmpty) {
      final url = Uri.parse('${EnvConfig.baseUrl}/user/account?phone=$phone');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          final userInfo = data[0];
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FriendDetailScreen(friend: userInfo),
              ),
            );
          }
        }
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    if (groupedFriends.isEmpty)
      return  Center(child: Text("Haven't had any friends yet").tr());

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
                onTap: () => openFriendDetail(friend),
                leading: (friend['imageUrl'] != null && friend['imageUrl'].toString().isNotEmpty)
                    ? CircleAvatar(
                  backgroundImage: NetworkImage(friend['imageUrl']),
                )
                    : const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(friend['name'] ?? 'Unname'.tr()),
                subtitle: Text(friend['phone'] ?? 'Do not have phone number').tr(),
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
                              builder: (context) => ChatDetailScreen(
                                name: friend['name'],
                                chatId: chatId.join('-'),
                                user: widget.user,
                                userId: widget.user.userID,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(icon: const Icon(Icons.call), onPressed: () {}),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _unfriend(friend['contactId'].toString());
                        },
                      ),
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

///Widget thông báo lời mời kết bạn
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
  void _fetchRequests() async {
    try {
      final requestsData = await FriendService.fetchRequests(widget.userId);
      setState(() {
        requests = requestsData;
      });
    } catch (e) {
      print("Lỗi khi lấy lời mời kết bạn: $e");
    }
  }

  /// Chấp nhận lời mời kết bạn
  Future<void> _acceptRequest(String senderId) async {
    final success = await FriendService.acceptRequest(widget.userId, senderId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Accepted").tr()));
      _fetchRequests();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Accept failed").tr()));
    }
  }

  /// Từ chối lời mời kết bạn
  Future<void> _denyRequest(String senderId) async {
    final success = await FriendService.denyRequest(widget.userId, senderId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Denied contact request").tr()),
      );
      _fetchRequests();
    } else if (success == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to deny request").tr()),
      );
    }
  }

  Future<void> openFriendDetail(Map<String, dynamic> friend) async {
    final phone = friend['senderPhone'];
    if (phone != null && phone.toString().isNotEmpty) {
      final url = Uri.parse('${EnvConfig.baseUrl}/user/account?phone=$phone');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          final userInfo = data[0];
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FriendDetailScreen(friend: userInfo),
              ),
            );
          }
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) return  Center(child: Text("No friend requests").tr());

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
          onTap: () => openFriendDetail(request),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: () => _acceptRequest(request['senderId']),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () => _denyRequest(request['senderId']),
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
      final grouped = await ChatApi.getGroupedGroups(widget.user.userID);
      if (!mapEquals(grouped, groupedGroups)) {
        setState(() {
          groupedGroups = grouped;
        });
      }
    } catch (e) {
      print("Group load fail: $e".tr());
    } finally {
      if (mounted) setState(() => isLoading = false);
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
            child: const Text('Create new group', style: TextStyle(color: Colors.blue)).tr(),
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : groupedGroups.isEmpty
              ?  Center(child: Text("Empty group").tr())
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
                    final name = group["chatName"] ?? "Unnamed Group".tr();
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
