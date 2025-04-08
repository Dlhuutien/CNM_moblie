import 'dart:io';

import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'chat_profile_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final String name;

  const ChatDetailScreen({super.key, required this.name});

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<String> _messages = [];
  bool _showEmojiPicker = false;

  String? _selectedFile;

  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        _messages.add(_messageController.text.trim());
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
      print("Selected file: $filePath");
    } else {
      print("File selection canceled");
    }
  }

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    // Yêu cầu quyền sử dụng mic
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

    // Xử lý file ghi âm tại filePath
    print("Recording saved to: $filePath");
  }

  @override
  void dispose() {
    _recorder!.closeRecorder();
    _recorder = null;
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
            Text(widget.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              // Add call functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.push_pin),
            onPressed: () {
              // Add pin functionality
            },
          ),
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
        onTap: _dismissEmojiPicker, // Dismiss emoji picker if user taps outside
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final isUserMessage = index % 2 == 0;
                  return Align(
                    alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
                    child: Card(
                      color: isUserMessage ? Colors.blue : Colors.grey[200],
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text(
                          _messages[index],
                          style: TextStyle(
                            color: isUserMessage ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_showEmojiPicker)
              SizedBox(
                height: 250,
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    _messageController.text += emoji.emoji;
                  },
                  config: Config(
                    columns: 7,
                    emojiSizeMax: 32,
                    verticalSpacing: 10,
                    horizontalSpacing: 10,
                    gridPadding: const EdgeInsets.all(5),
                    bgColor: Colors.white,
                    indicatorColor: Colors.blue,
                    iconColor: Colors.grey,
                    iconColorSelected: Colors.blue,
                    backspaceColor: Colors.red,
                    recentsLimit: 28,
                    tabIndicatorAnimDuration: kTabScrollDuration,
                    categoryIcons: const CategoryIcons(),
                    buttonMode: ButtonMode.MATERIAL,
                  ),
                ),
              ),

            if (_selectedFile != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Selected file: $_selectedFile", // Hiển thị đường dẫn tệp
                      style: TextStyle(color: Colors.green),
                    ),
                    SizedBox(height: 10),
                    // Nếu tệp là hình ảnh, thêm widget Image để hiển thị ảnh
                    // if (_selectedFile!.endsWith('.jpg') || _selectedFile!.endsWith('.png'))
                    //   Image.file(File(_selectedFile!)),
                    // Nếu tệp là PDF, hiển thị một biểu tượng PDF hoặc tên tệp
                    if (_selectedFile!.endsWith('.pdf'))
                      Icon(Icons.picture_as_pdf, color: Colors.red),
                  ],
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
