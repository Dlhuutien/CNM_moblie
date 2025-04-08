import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'contact_screen.dart';
import 'profile_screen.dart';
import 'setting_screen.dart';
import 'package:chating_app/data/user.dart';

class MainScreen extends StatefulWidget {
  final ObjectUser user;
  const MainScreen({super.key, required this.user});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const ChatScreen(),
      const ContactScreen(),
      ProfileScreen(user: widget.user),
      const SettingsScreen()
    ];

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: InputDecoration(
            hintText: "Search message, people",
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            fillColor: Colors.grey[200],
            filled: true,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Contacts"),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: "Profile"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
