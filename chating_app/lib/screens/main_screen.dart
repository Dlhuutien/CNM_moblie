import 'package:chating_app/screens/signUp_screen.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'contact_screen.dart'; // Import ContactScreen
import 'profile_screen.dart'; // Import ProfileScreen
import 'signUp_screen.dart'; // Import SignUpScreen

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  // List of screens for each tab
  final List<Widget> screens = [
    const ChatScreen(),
    const ContactScreen(), // Changed to ContactScreen
    const ProfileScreen(), // Changed to ProfileScreen
     SignUpScreen(), // Changed to SignUpScreen
  ];

  @override
  Widget build(BuildContext context) {
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

      // Display the selected screen based on the current index
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
