import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:chating_app/data/user.dart';
import 'package:chating_app/screens/chat_detail_screen.dart';

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
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Friend List'),
              Tab(text: 'Your Group'),
              Tab(text: 'Notification'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            FriendList(user: user),
            const GroupList(),
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
  List<dynamic> friends = [];

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  Future<void> _fetchFriends() async {
    final response = await http.get(Uri.parse("http://138.2.106.32/contact/list?userId=${widget.user.userID}"));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        friends = data['data'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) return const Center(child: Text("Chưa có bạn bè nào"));
    return ListView.builder(
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final friend = friends[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(friend['imageUrl']),
          ),
          title: Text(friend['name']),
          subtitle: Text(friend['phone']),
          trailing: SizedBox(
            width: 150, // đủ rộng cho 3 icon
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.message),
                  onPressed: () {
                    final chatId = [widget.user.userID, friend['contactId']]
                        .map((e) => e.toString())
                        .toList()
                      ..sort();

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailScreen(
                          name: friend['name'],
                          chatId: chatId.join('-'),
                          userId: widget.user.userID,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(icon: const Icon(Icons.call), onPressed: () {}),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {}),
              ],
            ),
          ),

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

  Future<void> _fetchRequests() async {
    final response = await http.get(Uri.parse("http://138.2.106.32/contact/requests?userId=${widget.userId}"));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        requests = data['data'];
      });
    }
  }

  Future<void> _acceptRequest(String senderId) async {
    final response = await http.post(
      Uri.parse("http://138.2.106.32/contact/accept?userId=${widget.userId}&senderId=$senderId"),
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
            backgroundImage: NetworkImage(request['senderImage']),
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

class GroupList extends StatelessWidget {
  const GroupList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () {},
            child: const Text('Create new group'),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: 3,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.group),
                title: Text('Group ${index + 1}'),
                trailing: const Icon(Icons.arrow_forward_ios),
              );
            },
          ),
        ),
      ],
    );
  }
}
