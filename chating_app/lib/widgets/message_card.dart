import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:chating_app/widgets/full_screen_image.dart';
import 'package:easy_localization/easy_localization.dart';

typedef MessageActionCallback = void Function(String action, Map<String, dynamic> message);

class MessageCard extends StatefulWidget {
  final Map<String, dynamic> message;
  final bool isUserMessage;
  final String Function(String?) formatTimestamp;
  final MessageActionCallback onAction;
  final bool isGroup; // Thêm isGroup

  //highlight tin nhắn search
  final bool highlight;
  final bool isCurrentSearch;

  final VoidCallback? onLongPress;

  const MessageCard({
    Key? key,
    required this.message,
    required this.isUserMessage,
    required this.formatTimestamp,
    required this.onAction,
    this.isGroup = false,
    this.highlight = false,
    this.isCurrentSearch = false,
    this.onLongPress,
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
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.5,
            ),
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: widget.isCurrentSearch
                  ? Colors.yellow.withOpacity(0.5)
                  : (widget.highlight
                  ? Colors.yellow.withOpacity(0.2)
                  : (() {
                if (Theme.of(context).brightness == Brightness.dark) {
                  if (widget.isUserMessage) {
                    return const Color(0xFF0D47A1); // màu xanh dương cho user trong dark
                  } else {
                    return Colors.grey.shade800; // nền xám cho người khác trong dark
                  }
                } else {
                  // Light theme giữ nguyên màu cũ
                  return widget.isUserMessage ? const Color(0xFFE0ECFC) : Colors.grey[200];
                }
              })()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: widget.isUserMessage
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (widget.isGroup && !widget.isUserMessage) ...[
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: widget.message['senderImage'] != null
                            ? NetworkImage(widget.message['senderImage'])
                            : const AssetImage('assets/profile.png') as ImageProvider,
                      ),
                      const SizedBox(width: 8),
                      // Text(
                      //   widget.message['senderName'] ?? 'Unknown',
                      //   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      // ),
                      // Thay style của tên người khác (nếu isGroup && !isUserMessage):
                      Text(
                        widget.message['senderName'] ?? 'Unknown',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],

                // Phần hiển thị tin nhắn như cũ
                if (widget.message['deleteReason'] == 'unsent')
                   Padding(
                    padding: EdgeInsets.only(top: 6.0),
                    child: Text(
                      'Message recalled'.tr(),
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  )
                else ...[
                  if (widget.message['replyTo'] != null) ...[
                    // _buildReplyPreview(widget.message['replyTo']),
                    _buildReplyPreview(widget.message['replyTo'], context, isUser: true)
                  ],
                  if (widget.message['attachmentUrl'] != null &&
                      widget.message['attachmentUrl'].toString().isNotEmpty)
                    _buildAttachmentWidget(widget.message['attachmentUrl']),
                  // Thay style phần nội dung message (RichText) để đổi màu chữ theo user/other và theme:
                  if (widget.message['content'] != null &&
                      widget.message['content'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? (widget.isUserMessage ? Colors.white : Colors.white)
                                : Colors.black,
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
    );
  }

  Widget _buildAttachmentWidget(String url) {
    final isImage = _isImageFile(url);
    final fileName = Uri.parse(url).pathSegments.last;
    final fileExt = fileName.split('.').last.toLowerCase();

    if (isImage) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FullScreenImage(imageUrl: url),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            width: 200,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Text('Can not upload picture').tr(),
          ),
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
          // subtitle: const Text("Click to download", style: TextStyle(color: Colors.white70)),
          trailing: const Icon(Icons.open_in_new, color: Colors.white),
          onTap: () {
            // downloadFile(context, url, fileName);
            openFileUrl(context, url);
          },
        ),
      );
    }
  }

  void _showMessageOptions(BuildContext context) {
    if (widget.message['deleteReason'] == 'unsent') return;

    final options = <Widget>[
      ListTile(
        leading: const Icon(Icons.reply),
        title: const Text('Reply').tr(),
        onTap: () {
          Navigator.pop(context);
          widget.onAction("reply", widget.message);
        },
      ),
      ListTile(
        leading: const Icon(Icons.forward),
        title: const Text('Forward').tr(),
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
          title: const Text('Delete').tr(),
          onTap: () {
            Navigator.pop(context);
            widget.onAction("delete", widget.message);
          },
        ),
        ListTile(
          leading: const Icon(Icons.undo),
          title: const Text('Undo').tr(),
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

  String extractRealUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.host.contains('google.com') && uri.path == '/url') {
      final realUrl = uri.queryParameters['url'];
      return realUrl ?? url;
    }
    return url;
  }

  ///Hàm chỉnh là text:http thành url
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
      final actualUrl = extractRealUrl(url);
      final actualUri = Uri.tryParse(actualUrl);
      if (actualUri != null) {
        final recognizer = TapGestureRecognizer()
          ..onTap = () async {
            await safeLaunchUrl(actualUri);
          };
        _recognizers.add(recognizer);

        spans.add(TextSpan(
          // text: url,
          text: actualUrl,
          style: const TextStyle(
              color: Colors.lightBlue, decoration: TextDecoration.underline),
          recognizer: recognizer,
        ));
        lastIndex = match.end;
      }
    }
    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return spans;
  }
}

Future<void> downloadFile(BuildContext context, String url, String fileName) async {
  if (!await Permission.manageExternalStorage.isGranted) {
    // Chưa có quyền, yêu cầu người dùng cấp quyền
    final granted = await Permission.manageExternalStorage.request();
    if (!granted.isGranted) {
      // Nếu từ chối, hỏi mở cài đặt
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("File management permission required to download.").tr(),
          action: SnackBarAction(
            label: "Setting".tr(),
            onPressed: () {
              openAppSettings();
            },
          ),
        ),
      );
      return;
    }
  }

  // Nếu quyền thì cho phét tải file
  try {
    final dir = await getExternalStorageDirectory();
    if (dir == null) throw Exception("Cannot find save folder".tr());

    final savePath = "${dir.path}/$fileName";
    final dio = Dio();

    await dio.download(
      url,
      savePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          debugPrint("Uploaded: ${(received / total * 100).toStringAsFixed(0)}%");
        }
      },
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Saved $fileName at: ${dir.path}").tr()),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Download file fail: $e")),
    );
  }
}

Future<void> openFileUrl(BuildContext context, String url) async {
  if (!await Permission.manageExternalStorage.isGranted) {
    final granted = await Permission.manageExternalStorage.request();
    if (!granted.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("File management permission required to open.").tr(),
          action: SnackBarAction(
            label: "Setting".tr(),
            onPressed: () => openAppSettings(),
          ),
        ),
      );
      return;
    }
  }

  final uri = Uri.tryParse(url);
  if (uri == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("URL không hợp lệ.")),
    );
    return;
  }

  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text("Cannot open file. Make sure you have the correct application..").tr()),
    );
  }
}

Future<void> safeLaunchUrl(Uri uri) async {
  if (!await launchUrl(uri, mode: LaunchMode.platformDefault)) {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      print("Không thể mở URL: $uri");
    }
  }
}

Future<bool> requestManageExternalStoragePermission() async {
  if (await Permission.manageExternalStorage.isGranted) {
    return true;
  }
  final status = await Permission.manageExternalStorage.request();
  return status.isGranted;
}

bool _isImageFile(String url) {
  final ext = url.toLowerCase().split('.').last;
  return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
}

Widget _buildReplyPreview(Map<String, dynamic> repliedMsg, BuildContext context, {bool isUser = false}) {
  final bool isImage = repliedMsg['attachmentUrl'] != null &&
      _isImageFile(repliedMsg['attachmentUrl']);

  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Container(
    decoration: BoxDecoration(
      color: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
      // color: isDark ? Colors.white : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(8),
      border: Border(
        left: BorderSide(
          color: Colors.blue.shade300,
          width: 4,
        ),
      ),
    ),
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
    margin: const EdgeInsets.only(bottom: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          repliedMsg['senderName'] ?? 'Unknown',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.orange,
          ),
        ),
        const SizedBox(height: 4),
        if (isImage)
          Row(
            children: [
              const Icon(Icons.image, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '[Picture]',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade800 : Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          )
        else
          Text(
            repliedMsg['content'] ?? 'Deleted message'.tr(),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    ),
  );
}

