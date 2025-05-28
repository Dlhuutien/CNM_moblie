 import 'package:flutter/material.dart';
 import 'package:easy_localization/easy_localization.dart';

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

  // void _confirmForward() {
  //   if (!mounted) return;
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     Navigator.pop(context, selectedIds.toList());
  //   });
  // }
  void _confirmForward() {
    if (!mounted) return;
    final editedMessage = _messageController.text.trim();
    Navigator.pop(context, {
      'receivers': selectedIds.toList(),
      'message': editedMessage,
    });
  }


  TextEditingController _messageController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _messageController.text = widget.message['content'] ?? '';
  }


  @override
  Widget build(BuildContext context) {
    final hasAttachment = widget.message['attachmentUrl'] != null && widget.message['attachmentUrl'].toString().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select friends/groups"),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text("Friends", style: TextStyle(fontWeight: FontWeight.bold)),
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
                  title: Text(friend['name'] ?? 'Unname').tr(),
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
           Padding(
            padding: EdgeInsets.all(8),
            child: Text("Group", style: TextStyle(fontWeight: FontWeight.bold)).tr(),
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
                  title: Text(group['chatName'] ?? 'Empty name group').tr(),
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
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasAttachment)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      height: 80,
                      child: Image.network(
                        widget.message['attachmentUrl'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration:  InputDecoration(
                          hintText: "Edit message...".tr(),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        minLines: 1,
                        maxLines: 4,
                        // Cho chỉnh sửa text nếu là file
                        // enabled: !hasAttachment,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      color: Colors.blue,
                      onPressed: selectedIds.isEmpty
                          ? null
                          : () {
                        final editedMessage = _messageController.text.trim();
                        Navigator.pop(context, {
                          'receivers': selectedIds.toList(),
                          'message': hasAttachment
                              ? widget.message
                              : editedMessage,
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  }