import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

typedef MessageActionCallback = void Function(String action, Map<String, dynamic> message);

class MessageCard extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isUserMessage;
  final String Function(String?) formatTimestamp;
  final MessageActionCallback onAction;

  const MessageCard({
    Key? key,
    required this.message,
    required this.isUserMessage,
    required this.formatTimestamp,
    required this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Nếu là message bị remove và là của chính người dùng thì ẩn
    if (message['deleteReason'] == 'remove' && isUserMessage) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onLongPress: () => _showMessageOptions(context),
      child: Listener(
        onPointerDown: (event) {
          if (event.kind == PointerDeviceKind.mouse &&
              event.buttons == kSecondaryMouseButton) {
            _showMessageOptions(context);
          }
        },
        child: Align(
          alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
          child: Card(
            color: isUserMessage ? Colors.blue : Colors.grey[200],
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment:
                isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (message['attachmentUrl'] != null &&
                      message['attachmentUrl'].toString().isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        message['attachmentUrl'],
                        width: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                        const Text('Error loading image'),
                      ),
                    ),
                  if (message['deleteReason'] == 'unsent')
                    const Padding(
                      padding: EdgeInsets.only(top: 6.0),
                      child: Text(
                        'Tin nhắn đã thu hồi',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  else if (message['content'] != null &&
                      message['content'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        message['content'],
                        style: TextStyle(
                          color: isUserMessage ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    formatTimestamp(message['timestamp']),
                    style: TextStyle(
                      fontSize: 10,
                      color: isUserMessage ? Colors.white : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    if (message['deleteReason'] == 'unsent') return;

    final options = <Widget>[
      ListTile(
        leading: const Icon(Icons.reply),
        title: const Text('Reply'),
        onTap: () {
          Navigator.pop(context);
          onAction("reply", message);
        },
      ),
      ListTile(
        leading: const Icon(Icons.forward),
        title: const Text('Forward'),
        onTap: () {
          Navigator.pop(context);
          onAction("forward", message);
        },
      ),
    ];

    if (isUserMessage) {
      options.addAll([
        ListTile(
          leading: const Icon(Icons.delete),
          title: const Text('Delete'),
          onTap: () {
            Navigator.pop(context);
            onAction("delete", message);
          },
        ),
        ListTile(
          leading: const Icon(Icons.undo),
          title: const Text('Undo'),
          onTap: () {
            Navigator.pop(context);
            onAction("undo", message);
          },
        ),
      ]);
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Wrap(children: options),
    );
  }
}
