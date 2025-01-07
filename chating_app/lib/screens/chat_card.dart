import 'package:flutter/material.dart';

class ChatCard extends StatelessWidget {
  final String name;
  final String message;
  final String time;
  final bool isPinned;
  final String imagePath;

  const ChatCard({
    super.key,
    required this.name,
    required this.message,
    required this.time,
    this.isPinned = false,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: AssetImage(imagePath),
      ),
      title: Text(name),
      subtitle: Text(message),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(time, style: TextStyle(color: Colors.grey)),
          if (isPinned)
            const Icon(
              Icons.push_pin,
              color: Colors.blue,
              size: 16,
            ),
        ],
      ),
    );
  }
}
