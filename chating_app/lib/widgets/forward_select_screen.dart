import 'package:flutter/material.dart';

class ForwardSelectScreen extends StatefulWidget {
  final Map<String, dynamic> message;
  final List<Map<String, dynamic>> friends;
  final List<Map<String, dynamic>> groups;

  const ForwardSelectScreen({
    Key? key,
    required this.message,
    required this.friends,
    required this.groups,
  }) : super(key: key);

  @override
  State<ForwardSelectScreen> createState() => _ForwardSelectScreenState();
}

class _ForwardSelectScreenState extends State<ForwardSelectScreen> {
  final Set<String> selectedIds = {};

  void _toggleSelection(String id) {
    setState(() {
      if (selectedIds.contains(id)) {
        selectedIds.remove(id);
      } else {
        selectedIds.add(id);
      }
    });
  }

  void _confirmForward() {
    Navigator.pop(context, selectedIds.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chọn bạn bè / nhóm"),
        actions: [
          TextButton(
            onPressed: selectedIds.isEmpty ? null : _confirmForward,
            child: Text(
              "Gửi",
              style: TextStyle(color: selectedIds.isEmpty ? Colors.grey[400] : Colors.white),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text("Bạn bè", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...widget.friends.map((friend) {
            final id = friend['id'].toString();
            return CheckboxListTile(
              title: Text(friend['name']),
              value: selectedIds.contains(id),
              onChanged: (_) => _toggleSelection(id),
            );
          }).toList(),
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text("Nhóm", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...widget.groups.map((group) {
            final id = group['id'].toString();
            return CheckboxListTile(
              title: Text(group['name']),
              value: selectedIds.contains(id),
              onChanged: (_) => _toggleSelection(id),
            );
          }).toList(),
        ],
      ),
    );
  }
}
