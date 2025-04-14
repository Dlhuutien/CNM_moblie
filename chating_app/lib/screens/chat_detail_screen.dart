import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'chat_profile_screen.dart';
import 'package:chating_app/services/websocket_service.dart';

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

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _showEmojiPicker = false;

  String? _selectedFile;
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  // late WebSocketService _webSocketService;
  WebSocketService? _webSocketService;

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _initializeRecorder();
    _fetchMessages();

    _webSocketService = WebSocketService(
      userId: widget.userId,
      chatId: widget.chatId,
      onMessage: (message) {
        setState(() {
          _messages.insert(0, message);
        });
      },
    );
    // _webSocketService.connect();
    _webSocketService?.connect();
  }

  Future<void> _fetchMessages() async {
    final url = Uri.parse("http://138.2.106.32/chat/${widget.chatId}/history/50?userId=${widget.userId}");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _messages = List<Map<String, dynamic>>.from(data['data']);
      });
    } else {
      print("L\u1ed7i t\u1ea3i tin nh\u1eafn: \${response.body}");
    }
  }
  String _formatTimestamp(String? iso) {
    if (iso == null || iso.isEmpty) return "";
    final dt = DateTime.tryParse(iso);
    if (dt == null) return "";
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }


  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isNotEmpty) {
      // _webSocketService.sendMessage(content);
      _webSocketService?.sendMessage(content);
      setState(() {
        _messages.insert(0, {
          "userId": widget.userId,
          "content": content,
          "timestamp": DateTime.now().toIso8601String(),
        });
      });
      _messageController.clear();
    }
  }

  void _toggleEmojiPicker() {
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
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'pdf', 'doc'],
    );
    if (result != null) {
      String filePath = result.files.single.path!;
      setState(() {
        _selectedFile = filePath;
      });
      print("Selected file: \$filePath");
    } else {
      print("File selection canceled");
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
    print("Recording saved to: \$filePath");
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    // _webSocketService.close();
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
                  builder: (context) => ChatProfileScreen(name: widget.name),
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
            Expanded(
              child: ListView.builder(
                reverse: true,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isUserMessage = message['userId'].toString() == widget.userId;

                  return Align(
                    alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
                    child: Card(
                      color: isUserMessage ? Colors.blue : Colors.grey[200],
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment:
                          isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              message['content'] ?? '',
                              style: TextStyle(
                                color: isUserMessage ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTimestamp(message['timestamp']),
                              style: TextStyle(
                                fontSize: 10,
                                color: isUserMessage ? Colors.white : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
          ],
        ),
      ),
    );
  }
}