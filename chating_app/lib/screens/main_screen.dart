import 'package:chating_app/services/notification_poller.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'contact_screen.dart';
import 'profile_screen.dart';
import 'setting_screen.dart';
import 'package:chating_app/data/user.dart';
import 'search_user_screen.dart';
import 'package:easy_localization/easy_localization.dart';

class MainScreen extends StatefulWidget {
  final ObjectUser user;
  const MainScreen({super.key, required this.user});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;
  late NotificationPoller _poller;

  @override
  void initState() {
    super.initState();
    _poller = NotificationPoller(widget.user);
    _poller.start();
  }
  @override
  void dispose() {
    _poller.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      ChatScreen(user: widget.user),
      ContactScreen(user: widget.user),
      ProfileScreen(user: widget.user),
      SettingsScreen(user: widget.user),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.blue, width: 1),
            ),
            padding: EdgeInsets.all(8),
            child: Icon(Icons.chat_outlined, color: Colors.blue),
          ),
          onPressed: () {
            setState(() {
              currentIndex = 0;
            });
          },
        ),
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SearchUserScreen(user: widget.user),
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.grey),
                SizedBox(width: 5),
                Flexible(
                  child: Text(
                    "Searching user...".tr(),
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ).tr(),
                ),
              ],
            ),
          ),
        ),
        backgroundColor: Colors.blue,
      ),
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items:  [
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat".tr()),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Contacts".tr()),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle), label: "Profile".tr()),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: "Settings".tr()),
        ],
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
