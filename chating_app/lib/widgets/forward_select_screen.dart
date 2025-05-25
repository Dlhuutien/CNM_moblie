import 'package:flutter/material.dart';

class ForwardSelectScreen extends StatefulWidget {
  final Map<String, dynamic> message;
  final List<Map<String, dynamic>> friends;
  final List<Map<String, dynamic>> groups;
  final String currentUserId;

  const ForwardSelectScreen({
    Key? key,
    required this.message,
    required this.friends,
    required this.groups,
    required this.currentUserId,
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
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pop(context, selectedIds.toList());
    });
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
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text("Bạn bè", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.friends.length,
              itemBuilder: (context, index) {
                final friend = widget.friends[index];
                final friendId = friend['contactId'].toString();
                final id = '${widget.currentUserId}-$friendId';
                print('Friend index=$index, id=$id');
                return CheckboxListTile(
                  key: ValueKey(id),
                  title: Text(friend['name'] ?? 'Không tên'),
                  value: selectedIds.contains(id),
                  onChanged: (bool? value) {
                    if (value == null) return;
                    setState(() {
                      if (value) {
                        selectedIds.add(id);
                      } else {
                        selectedIds.remove(id);
                      }
                    });
                  },
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text("Nhóm", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.groups.length,
              itemBuilder: (context, index) {
                final group = widget.groups[index];
                final groupChatId = group['ChatID'].toString();
                final id = groupChatId;
                print('Group index=$index, id=$id');
                return CheckboxListTile(
                  key: ValueKey(id),
                  title: Text(group['chatName'] ?? 'Nhóm không tên'),
                  value: selectedIds.contains(id),
                  onChanged: (bool? value) {
                    if (value == null) return;
                    setState(() {
                      if (value) {
                        selectedIds.add(id);
                      } else {
                        selectedIds.remove(id);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
