import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState(); // Sửa tên lớp
}

class _MainScreenState extends State<MainScreen> { // Sửa tên lớp
  int currentIndex = 0;

  // List of screens for each tab
  final List<Widget> screens = [
    Center(child: Text("Chat Screen")),
    Center(child: Text("Contacts Screen")),
    Center(child: Text("Settings Screen")),
    Center(child: Text("Profile Screen")),
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
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: "Profile"),
        ],
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
