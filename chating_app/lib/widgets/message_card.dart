import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

typedef MessageActionCallback = void Function(String action, Map<String, dynamic> message);

class MessageCard extends StatefulWidget {
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
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.message['deleteReason'] == 'remove' && widget.isUserMessage) {
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
          alignment: widget.isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
          child: Card(
            color: widget.isUserMessage ? const Color(0xFFE0ECFC) : Colors.grey[200],
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: widget.isUserMessage
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (widget.message['deleteReason'] == 'unsent')
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
                  else ...[
                    if (widget.message['attachmentUrl'] != null &&
                        widget.message['attachmentUrl'].toString().isNotEmpty)
                      _buildAttachmentWidget(widget.message['attachmentUrl']),
                    if (widget.message['content'] != null &&
                        widget.message['content'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: widget.isUserMessage ? Colors.black : Colors.black,
                            ),
                            children: _buildTextWithLinks(widget.message['content'] ?? ""),
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    widget.formatTimestamp(widget.message['timestamp']),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Phân biệt ảnh và file
  Widget _buildAttachmentWidget(String url) {
    final isImage = _isImageFile(url);
    final fileName = Uri.parse(url).pathSegments.last;
    final fileExt = fileName.split('.').last.toLowerCase();

    if (isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
          const Text('Không thể tải ảnh'),
        ),
      );
    } else {
      IconData icon = Icons.insert_drive_file;
      if (fileExt == 'pdf') icon = Icons.picture_as_pdf;
      else if (fileExt == 'doc' || fileExt == 'docx') icon = Icons.description;
      else if (fileExt == 'dll' || fileExt == 'exe') icon = Icons.bug_report;
      else if (fileExt == 'txt') icon = Icons.text_snippet;

      return Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          leading: Icon(icon, color: Colors.white),
          title: Text(
            fileName,
            style: const TextStyle(color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: const Text("Click to download", style: TextStyle(color: Colors.white70)),
          trailing: const Icon(Icons.download, color: Colors.white),
          onTap: () {
            downloadFile(context, url, fileName);
          },
        ),
      );
    }
  }

  Future<void> openUrlSmart(BuildContext context, String url) async {
    final uri = Uri.parse(url);

    final modes = [
      LaunchMode.externalApplication,
      LaunchMode.inAppBrowserView,
      LaunchMode.inAppWebView,
      LaunchMode.platformDefault,
    ];

    for (final mode in modes) {
      try {
        final canLaunchExternal = await canLaunchUrl(uri);
        if (canLaunchExternal) {
          final success = await launchUrl(uri, mode: mode);
          if (success) return;
        }
      } catch (_) {}
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Không tìm được ứng dụng để mở file.")),
    );
  }


  bool _isImageFile(String url) {
    final ext = url.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  }

  void _showMessageOptions(BuildContext context) {
    if (widget.message['deleteReason'] == 'unsent') return;

    final options = <Widget>[
      ListTile(
        leading: const Icon(Icons.reply),
        title: const Text('Reply'),
        onTap: () {
          Navigator.pop(context);
          widget.onAction("reply", widget.message);
        },
      ),
      ListTile(
        leading: const Icon(Icons.forward),
        title: const Text('Forward'),
        onTap: () {
          Navigator.pop(context);
          widget.onAction("forward", widget.message);
        },
      ),
    ];

    if (widget.isUserMessage) {
      options.addAll([
        ListTile(
          leading: const Icon(Icons.delete),
          title: const Text('Delete'),
          onTap: () {
            Navigator.pop(context);
            widget.onAction("delete", widget.message);
          },
        ),
        ListTile(
          leading: const Icon(Icons.undo),
          title: const Text('Undo'),
          onTap: () {
            Navigator.pop(context);
            widget.onAction("undo", widget.message);
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

  List<InlineSpan> _buildTextWithLinks(String text) {
    final urlRegex = RegExp(
        r'(https?:\/\/(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&/=]*))');
    final matches = urlRegex.allMatches(text);
    if (matches.isEmpty) return [TextSpan(text: text)];

    List<InlineSpan> spans = [];
    int lastIndex = 0;

    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }
      final url = match.group(0)!;
      final recognizer = TapGestureRecognizer()
        ..onTap = () async {
          final uri = Uri.tryParse(url);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        };
      _recognizers.add(recognizer);

      spans.add(TextSpan(
        text: url,
        style: const TextStyle(color: Colors.lightBlue, decoration: TextDecoration.underline),
        recognizer: recognizer,
      ));
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return spans;
  }
}
Future<void> downloadFile(BuildContext context, String url, String fileName) async {
  try {
    // Yêu cầu quyền lưu trữ
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cần quyền lưu trữ để tải file.")),
      );
      return;
    }

    final dir = await getExternalStorageDirectory(); // Android only
    if (dir == null) throw Exception("Không tìm được thư mục lưu");

    final savePath = "${dir.path}/$fileName";
    final dio = Dio();

    await dio.download(
      url,
      savePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          debugPrint("Đã tải: ${(received / total * 100).toStringAsFixed(0)}%");
        }
      },
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Đã lưu $fileName tại: ${dir.path}")),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Tải file thất bại: $e")),
    );
  }
}