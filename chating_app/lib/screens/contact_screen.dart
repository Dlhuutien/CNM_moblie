import 'package:flutter/material.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          // title: const Text('Contact'),
          toolbarHeight: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Friend List'),
              Tab(text: 'Your Group'),
              Tab(text: 'Notification'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            FriendList(),
            GroupList(),
            NotificationList(),
          ],
        ),
      ),
    );
  }
}

class FriendList extends StatelessWidget {
  const FriendList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const CircleAvatar(
            backgroundImage: AssetImage('assets/images/Introduction_profile.png'),
          ),
          title: Text('Friend ${index + 1}'),
          subtitle: Text('Hello, I\'m Friend ${index + 1}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              IconButton(
                icon: Icon(Icons.message),
                onPressed: null,
              ),
              IconButton(
                icon: Icon(Icons.call),
                onPressed: null,
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: null,
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

class NotificationList extends StatelessWidget {
  const NotificationList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 4,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const CircleAvatar(
            backgroundImage: AssetImage('assets/profile.png'),
          ),
          title: Text('Notification ${index + 1}'),
          subtitle: const Text('You have a new friend request'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              IconButton(
                icon: Icon(Icons.check, color: Colors.green),
                onPressed: null,
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.red),
                onPressed: null,
              ),
            ],
          ),
        );
      },
    );
  }
}
