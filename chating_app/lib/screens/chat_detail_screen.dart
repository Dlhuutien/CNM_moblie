import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'chat_profile_screen.dart';
import 'package:chating_app/services/websocket_service.dart';
import 'package:chating_app/widgets/message_card.dart';
import 'package:chating_app/services/chat_api.dart';
import 'package:image_picker/image_picker.dart';


class ChatDetailScreen extends StatefulWidget {
  final String name;
  final String chatId;
  final String userId;

  const ChatDetailScreen({
    super.key,
    required this.name,
    required this.chatId,
    required this.userId,
  });

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _showEmojiPicker = false;

  String? _selectedFile;
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  WebSocketService? _webSocketService;

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    final isKeyboardVisible = bottomInset > 0.0;

    if (isKeyboardVisible && _showEmojiPicker) {
      setState(() {
        _showEmojiPicker = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _recorder = FlutterSoundRecorder();
    _initializeRecorder();
    _fetchMessages();

    _webSocketService = WebSocketService(
      userId: widget.userId,
      chatId: widget.chatId,
      onMessage: (message) {
        if (message['type'] == 'change') {
          if (message['deleteType'] == 'remove') {
            setState(() {
              _messages.removeWhere((m) => m['messageId'] == message['msgId']);
            });
          } else if (message['deleteType'] == 'unsent') {
            setState(() {
              final index = _messages.indexWhere((m) => m['messageId'] == message['msgId']);
              if (index != -1) {
                _messages[index]['deleteReason'] = 'unsent';
                _messages[index]['content'] = 'Tin nhắn đã thu hồi';
              }
            });
          }
        } else {
          message['deleteReason'] ??= null;
          setState(() {
            _messages.insert(0, message);
          });
        }
      },

    );

    _webSocketService?.connect();
  }

  Future<void> _fetchMessages() async {
    try {
      final messages = await ChatApi.fetchMessages(widget.chatId, widget.userId);
      setState(() {
        _messages = messages;
      });
    } catch (e) {
      print("Lỗi fetchMessages: $e");
    }
  }

  String _formatTimestamp(String? iso) {
    if (iso == null || iso.isEmpty) return "";
    final dt = DateTime.tryParse(iso);
    if (dt == null) return "";

    // Chuyển từ UTC -> Local (client device)
    final localTime = dt.toLocal();

    return "${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}";
  }


  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isNotEmpty) {
      _webSocketService?.sendMessage(content);
      _messageController.clear();
    }
  }

  void _toggleEmojiPicker() async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
    });
  }

  void _dismissEmojiPicker() {
    if (_showEmojiPicker) {
      setState(() {
        _showEmojiPicker = false;
      });
    }
  }

  Future<void> _pickFile() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final uploadedUrl = await ChatApi.uploadImage(pickedFile);
      if (uploadedUrl != null) {
        _webSocketService?.sendMessageWithAttachment(
          content: "Đã gửi một ảnh",
          attachmentUrl: uploadedUrl,
        );
      } else {
        print("Lỗi khi upload ảnh");
      }
    } else {
      print("Đã hủy chọn ảnh");
    }
  }

  Future<void> _initializeRecorder() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException("Mic permission not granted");
    }
    await _recorder!.openRecorder();
  }

  Future<void> _startRecording() async {
    await _recorder!.startRecorder(toFile: 'voice_message.aac');
    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopRecording() async {
    String? filePath = await _recorder!.stopRecorder();
    setState(() {
      _isRecording = false;
    });
    print("Recording saved to: $filePath");
  }

  void _handleMessageAction(String action, Map<String, dynamic> message) async {
    final messageId = message['messageId'];
    if (messageId == null) {
      print("Không thể xử lý vì messageId bị null.");
      return;
    }

    final deleteType = action == "undo" ? "unsent" : "remove";

    final success = await ChatApi.deleteMessage(
        messageId.toString(), deleteType);

    if (success) {
      setState(() {
        if (deleteType == "unsent") {
          message['deleteReason'] = 'unsent';
          message['content'] = 'Tin nhắn đã thu hồi';
        } else if (deleteType == "remove") {
          _messages.removeWhere((m) => m['messageId'] == messageId);
        }
      });
    } else {
      print("Lỗi khi $action");
    }
  }

    @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recorder?.closeRecorder();
    _webSocketService?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                widget.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.call), onPressed: () {}),
          IconButton(icon: const Icon(Icons.push_pin), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatProfileScreen(
                    chatId: widget.chatId,
                    userId: widget.userId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: _dismissEmojiPicker,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isUserMessage = message['userId'].toString() == widget.userId;
                    return MessageCard(
                      message: message,
                      isUserMessage: isUserMessage,
                      formatTimestamp: _formatTimestamp,
                      onAction: _handleMessageAction,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.emoji_emotions),
                      color: Colors.yellow,
                      onPressed: _toggleEmojiPicker,
                    ),
                    IconButton(
                      icon: const Icon(Icons.link),
                      onPressed: _pickFile,
                    ),
                    IconButton(
                      icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                      color: _isRecording ? Colors.red : Colors.blue,
                      onPressed: () {
                        if (_isRecording) {
                          _stopRecording();
                        } else {
                          _startRecording();
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      color: Colors.blue,
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
              if (_showEmojiPicker)
                SizedBox(
                  height: 300,
                  child: EmojiPicker(
                    onEmojiSelected: (category, emoji) {
                      _messageController.text += emoji.emoji;
                      _messageController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _messageController.text.length),
                      );
                    },
                    onBackspacePressed: () {
                      _messageController.text = _messageController.text.characters.skipLast(1).toString();
                      _messageController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _messageController.text.length),
                      );
                    },
                    textEditingController: _messageController,
                    config: Config(
                      height: 300,
                      checkPlatformCompatibility: true,
                      emojiViewConfig: EmojiViewConfig(
                        emojiSizeMax: 28 *
                            (foundation.defaultTargetPlatform == TargetPlatform.iOS ? 1.20 : 1.0),
                      ),
                      categoryViewConfig: const CategoryViewConfig(),
                      bottomActionBarConfig: const BottomActionBarConfig(),
                      searchViewConfig: const SearchViewConfig(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}