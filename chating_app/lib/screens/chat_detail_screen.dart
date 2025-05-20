import 'dart:io';
import 'package:chating_app/data/user.dart';
import 'package:chating_app/screens/chat_group_profile_screen.dart';
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
  final ObjectUser user;
  final bool isGroup;

  const ChatDetailScreen({
    super.key,
    required this.name,
    required this.chatId,
    required this.userId,
    required this.user,
    this.isGroup = false,
  });

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _showEmojiPicker = false;

  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  WebSocketService? _webSocketService;

  //Tìm kiếm
  bool _isSearching = false;
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  //Số lượng search tin nhắn trùng
  int _currentSearchIndex = 0;
  final _listViewController = ScrollController();


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
          message['timestamp'] ??= DateTime.now().toIso8601String();
          setState(() {
            _messages.insert(0, message);
          });
        }
      },
    );

    _webSocketService?.connect();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recorder?.closeRecorder();
    _webSocketService?.close();
    super.dispose();
  }

  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    if (bottomInset > 0 && _showEmojiPicker) {
      setState(() => _showEmojiPicker = false);
    }
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
    final dt = DateTime.tryParse(iso)?.toLocal();
    return dt != null ? "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}" : "";
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isNotEmpty) {
      _webSocketService?.sendMessage(content, widget.user.hoTen, widget.user.image);
      _messageController.clear();
    }
  }

  void _toggleEmojiPicker() async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => _showEmojiPicker = !_showEmojiPicker);
  }

  void _dismissEmojiPicker() {
    if (_showEmojiPicker) {
      setState(() => _showEmojiPicker = false);
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
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    String? filePath = await _recorder!.stopRecorder();
    setState(() => _isRecording = false);
    print("Recording saved to: $filePath");
  }

  Future<void> _pickFile() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text("Chọn ảnh từ thư viện"),
              onTap: () => Navigator.pop(context, 'image'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text("Chọn tệp từ thiết bị"),
              onTap: () => Navigator.pop(context, 'file'),
            ),
          ],
        ),
      ),
    );

    if (selected == 'image') {
      final XFile? pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedImage != null) {
        final url = await ChatApi.uploadImage(pickedImage);
        if (url != null) {
          _webSocketService?.sendMessageWithAttachment(
            content: "Đã gửi một ảnh",
            attachmentUrl: url,
          );
        }
      }
    } else if (selected == 'file') {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final uploaded = await ChatApi.uploadFile(file.path!, file.name);
        if (uploaded != null) {
          final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(file.extension?.toLowerCase());
          _webSocketService?.sendMessageWithAttachment(
            content: isImage ? "Đã gửi một ảnh" : "Đã gửi một tệp tin: ${file.name}",
            attachmentUrl: uploaded['url']!,
          );
        }
      }
    }
  }

  void _handleMessageAction(String action, Map<String, dynamic> message) async {
    final messageId = message['messageId'];
    if (messageId == null) return;

    final deleteType = action == "undo" ? "unsent" : "remove";

    final success = await ChatApi.deleteMessage(messageId.toString(), deleteType);
    if (success) {
      setState(() {
        if (deleteType == "unsent") {
          message['deleteReason'] = 'unsent';
          message['content'] = 'Tin nhắn đã thu hồi';
        } else {
          _messages.removeWhere((m) => m['messageId'] == messageId);
        }
      });
    }
  }

  void _scrollToSearchResult() {
    final targetMsgId = _searchResults[_currentSearchIndex]['messageId'];
    final indexInAll = _messages.indexWhere((m) => m['messageId'] == targetMsgId);

    if (indexInAll != -1) {
      _listViewController.animateTo(
        indexInAll * 100.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Tìm kiếm tin nhắn...',
            border: InputBorder.none,
          ),
          onChanged: (query) {
            setState(() {
              _searchResults = _messages
                  .where((msg) =>
              msg['content'] != null &&
                  msg['content'].toLowerCase().contains(query.toLowerCase()))
                  .toList();
              _currentSearchIndex = 0;
              if (_searchResults.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToSearchResult();
                });
              }
            });
          },
        )
            : Text(widget.name),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _searchResults.clear();
                  _currentSearchIndex = 0;
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Chức năng gọi sẽ được cập nhật sau")),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => widget.isGroup
                      ? ChatGroupProfileScreen(chatId: widget.chatId, userId: widget.userId, user: widget.user)
                      : ChatProfileScreen(chatId: widget.chatId, userId: widget.userId),
                ),
              );
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: _dismissEmojiPicker,
        child: Column(
          children: [
            if (_isSearching && _searchResults.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      "${_currentSearchIndex + 1}/${_searchResults.length}",
                      style: const TextStyle(fontSize: 13),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: () {
                        if (_currentSearchIndex > 0) {
                          setState(() => _currentSearchIndex--);
                          _scrollToSearchResult();
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios),
                      onPressed: () {
                        if (_currentSearchIndex < _searchResults.length - 1) {
                          setState(() => _currentSearchIndex++);
                          _scrollToSearchResult();
                        }
                      },
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: _listViewController,
                reverse: true,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isUserMessage = message['userId'].toString() == widget.userId;
                  final isCurrentSearchMatch = _searchResults.isNotEmpty &&
                      _searchResults[_currentSearchIndex]['messageId'] == message['messageId'];

                  return MessageCard(
                    key: ValueKey(message['messageId']),
                    message: message,
                    isUserMessage: isUserMessage,
                    formatTimestamp: _formatTimestamp,
                    onAction: _handleMessageAction,
                    isGroup: widget.isGroup,
                    highlight: isCurrentSearchMatch,
                  );
                },
              )
            ),
            if (!_isSearching)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: TextStyle(fontSize: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions),
                    color: Colors.orange,
                    onPressed: _toggleEmojiPicker,
                  ),
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: _pickFile,
                  ),
                  IconButton(
                    icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                    color: _isRecording ? Colors.red : Colors.blue,
                    onPressed: () {
                      _isRecording ? _stopRecording() : _startRecording();
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
                    emojiViewConfig: EmojiViewConfig(
                      emojiSizeMax: 28 *
                          (foundation.defaultTargetPlatform == TargetPlatform.iOS ? 1.2 : 1.0),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}