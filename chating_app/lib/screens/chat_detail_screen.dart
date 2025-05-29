import 'package:chating_app/data/user.dart';
import 'package:chating_app/screens/chat_group_profile_screen.dart';
import 'package:chating_app/services/websocket_service.dart';
import 'package:chating_app/widgets/message_card.dart';
import 'package:chating_app/services/chat_api.dart';
import 'package:chating_app/widgets/forward_select_screen.dart';
import 'chat_profile_screen.dart';
import 'package:chating_app/services/friend_service.dart';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';

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
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  //Số lượng search tin nhắn trùng
  int _currentSearchIndex = 0;
  final _listViewController = ScrollController();

  //Reply
  Map<String, dynamic>? _replyingMessage;


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
                _messages[index]['content'] = 'Message recalled';
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

  @override
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
      print("Error fetchMessages: $e");
    }
  }

  String _formatTimestamp(String? iso) {
    if (iso == null || iso.isEmpty) return "";
    final dt = DateTime.tryParse(iso)?.toLocal();
    return dt != null ? "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}" : "";
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    final hasImage = _selectedImageUrl != null;

    if (content.isNotEmpty || hasImage) {
      if (hasImage) {
        _webSocketService?.sendMessageWithAttachment(
          content: content.isNotEmpty ? content : "Sent a photo".tr(),
          attachmentUrl: _selectedImageUrl!,
          // replyToMessage: _replyingMessage,
        );
      } else {
        _webSocketService?.sendMessage(
          content,
          widget.user.hoTen,
          widget.user.image,
          replyToMessage: _replyingMessage,
        );
      }

      _messageController.clear();
      setState(() {
        _replyingMessage = null;
        _selectedImageUrl = null; // Xóa ảnh đã chọn sau khi gửi
      });
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
      throw RecordingPermissionException("Mic permission not granted".tr());
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
    print("Recording saved to: $filePath".tr());
  }

  String? _selectedImageUrl;
  Future<void> _pickFile() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Take photo").tr(),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text("Select photo from library").tr(),
              onTap: () => Navigator.pop(context, 'image'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text("Select file from device").tr(),
              onTap: () => Navigator.pop(context, 'file'),
            ),
          ],
        ),
      ),
    );

    if (selected == 'camera') {
      final XFile? capturedImage = await ImagePicker().pickImage(source: ImageSource.camera);
      if (capturedImage != null) {
        final url = await ChatApi.uploadImage(capturedImage);
        if (url != null) {
          setState(() {
            _selectedImageUrl = url; // Lưu url ảnh để preview và gửi sau
          });
        }
      }
    } else if (selected == 'image') {
      final XFile? pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedImage != null) {
        final url = await ChatApi.uploadImage(pickedImage);
        if (url != null) {
          setState(() {
            _selectedImageUrl = url;
          });
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
            content: isImage ? "Sent a photo".tr() : "Sent a file: ${file.name}".tr(),
            attachmentUrl: uploaded['url']!,
          );
        }
      }
    }
  }


  void _forwardMessageToSelected(
      Map<String, dynamic> message,
      List<String> targetChatIds,
      List friends,
      List groups,
      ) {
    for (String chatId in targetChatIds) {
      try {
        final ws = WebSocketService(
          userId: widget.userId,
          chatId: chatId,
          onMessage: (msg) {
            print("[WS] Message received: $msg");
          },
        );

        ws.connect().then((_) {
          final String content = message['content'] ?? "";
          final String senderName = message['senderName'] ?? "";
          final String senderImage = message['senderImage'] ?? "";
          final String? attachmentUrl = message['attachmentUrl'];

          // Nếu là tin nhắn đính kèm file, ảnh, voice
          if (attachmentUrl != null && attachmentUrl.isNotEmpty) {
            ws.sendMessageWithAttachment(
              content: content.isNotEmpty ? content : "Forwarded a file".tr(),
              attachmentUrl: attachmentUrl,
              isForward: true,
            );
          } else {
            // Tin nhắn văn bản
            ws.sendMessage(
              content,
              senderName,
              senderImage,
              isForward: true,
            );
          }
        });

        print("[FORWARD WS] Đã gửi tin nhắn forward đến chatId: $chatId");
      } catch (e) {
        print("[FORWARD WS] Lỗi khi gửi forward tới $chatId: $e");
      }
    }
  }

  List<Map<String, dynamic>> _flattenGroupedData(Map<String, List<Map<String, dynamic>>> groupedData) {
    return groupedData.values.expand((list) => list).toList();
  }

  ///Action giữ tin nhắn
  void _handleMessageAction(String action, Map<String, dynamic> message) async {
    if (action == "reply") {
      message['deleteReason'] = null;
      if (action == 'reply') {
        _startReplyToMessage(message);
      }
      // Không gọi API deleteMessage cho reply/forward
      return;
    }

    print("Action: $action, message: $message");
    if (action == "forward") {
      final friendsGrouped = await FriendService.getGroupedFriends(widget.userId);
      final groupsGrouped = await ChatApi.getGroupedGroups(widget.userId);

      final friendsList = _flattenGroupedData(friendsGrouped);
      final groupsList = _flattenGroupedData(groupsGrouped);

      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (_) => ForwardSelectScreen(
            message: message,
            friends: friendsList,
            groups: groupsList,
            currentUserId: widget.userId,
          ),
        ),
      );

      if (!mounted) return;
      if (result != null) {
        final List<String> targetChatIds = List<String>.from(result['receivers'] ?? []);

        final dynamic messageData = result['message'];
        String editedMessage = '';

        if (messageData is String) {
          editedMessage = messageData;
        } else if (messageData is Map<String, dynamic>) {
          editedMessage = messageData['content'] ?? '';
        }

        final forwardedMessage = {
          ...message,
          'content': editedMessage,
        };

        _forwardMessageToSelected(forwardedMessage, targetChatIds, friendsList, groupsList);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Message forwarded successfully!').tr()),
        );
      }
      return;
    }

    // Nếu action là xóa, thu hồi (undo), mới gọi API
    final messageId = message['messageId'];
    if (messageId == null) return;

    final deleteType = action == "undo" ? "unsent" : "remove";

    final success = await ChatApi.deleteMessage(messageId.toString(), deleteType);
    if (success) {
      setState(() {
        if (deleteType == "unsent") {
          message['deleteReason'] = 'unsent';
          message['content'] = 'Message recalled'.tr();
        } else {
          _messages.removeWhere((m) => m['messageId'] == messageId);
        }
      });
    }
  }


  ///Trỏ đúng vị trí tìm kiếm tin nhắn
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

  ///Reply tin nhắn
  void _startReplyToMessage(Map<String, dynamic> message) {
    setState(() {
      _replyingMessage = message;
    });
    print("Replying to: ${_replyingMessage?['messageId']?.runtimeType} | value: ${_replyingMessage?['messageId']}");
    print("Replying to: ${_replyingMessage?['messageId']}, deleteReason: ${_replyingMessage?['deleteReason']}");
  }

  ///Hàm check phân ngày
  bool _isDifferentDay(String date1, String date2) {
    final d1 = DateTime.parse(date1).toLocal();
    final d2 = DateTime.parse(date2).toLocal();
    return d1.year != d2.year || d1.month != d2.month || d1.day != d2.day;
  }

  ///Hàm format phân ngày
  String _formatDateLabel(String iso) {
    if (iso.isEmpty) return "";
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return "";
    // Format: "HH:mm dd/MM/yyyy"
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} ${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
  }

  ///Widget phân ngày
  Widget _buildDateSeparator(String isoDate) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatDateLabel(isoDate),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ),
      ),
    );
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
          decoration:  InputDecoration(
            hintText: 'Search messages...'.tr(),
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
                 SnackBar(content: Text("Call function will be updated later").tr()),
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
            if (_replyingMessage != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Replying to: ${_replyingMessage!['content'] ?? 'Message'.tr()}".tr(),
                        style: TextStyle(fontStyle: FontStyle.italic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 20),
                      onPressed: () {
                        setState(() {
                          _replyingMessage = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            if (_selectedImageUrl != null)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                height: 100,
                child: Stack(
                  children: [
                    Image.network(_selectedImageUrl!, fit: BoxFit.cover),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _selectedImageUrl = null;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
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

                    List<Widget> messageWidgets = [];

                    // Nếu là tin nhắn đầu tiên hoặc khác ngày với tin nhắn kế tiếp thì chèn ngày
                    bool showDateSeparator = false;
                    if (index == _messages.length - 1) {
                      // Tin nhắn cuối cùng (cũ nhất) luôn hiển thị ngày
                      showDateSeparator = true;
                    } else {
                      final currentTimestamp = message['timestamp'] ?? '';
                      final nextTimestamp = _messages[index + 1]['timestamp'] ?? '';
                      if (_isDifferentDay(currentTimestamp, nextTimestamp)) {
                        showDateSeparator = true;
                      }
                    }

                    if (showDateSeparator) {
                      messageWidgets.add(_buildDateSeparator(message['timestamp'] ?? ''));
                    }

                    messageWidgets.add(MessageCard(
                      key: ValueKey(message['messageId']),
                      message: message,
                      isUserMessage: isUserMessage,
                      formatTimestamp: _formatTimestamp,
                      onAction: _handleMessageAction,
                      isGroup: widget.isGroup,
                      highlight: isCurrentSearchMatch,
                    ));

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: messageWidgets,
                    );
                  }
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
                        hintText: "Type a message...".tr(),
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