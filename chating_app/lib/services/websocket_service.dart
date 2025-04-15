import 'dart:convert';
import 'dart:io';

class WebSocketService {
  final String userId;
  final String chatId;
  final Function(Map<String, dynamic>) onMessage;

  WebSocket? _socket;

  WebSocketService({
    required this.userId,
    required this.chatId,
    required this.onMessage,
  });

  Future<void> connect() async {
    try {
      _socket = await WebSocket.connect("ws://138.2.106.32/ws");

      // Gửi sự kiện join socket
      _socket?.add(jsonEncode({
        "type": "joinSocket",
        "userID": userId,
      }));

      // Gửi sự kiện join chat
      _socket?.add(jsonEncode({
        "type": "joinChat",
        "chatId": chatId,
      }));

      // Lắng nghe tin nhắn từ server
      _socket?.listen((data) {
        final decoded = jsonDecode(data);
        if (decoded["type"] == "receiveChat") {
          onMessage(decoded["message"]);
        } else if (decoded["type"] == "changeMessageType") {
          final msgId = decoded["msgId"];
          final deleteType = decoded["deleteType"];
          onMessage({
            "type": "change",
            "msgId": msgId,
            "deleteType": deleteType,
          });
        } else if (decoded["type"] == "ok" && decoded["originalType"] == "sendChat") {
          final msgPayload = decoded["messagePayload"];
          onMessage({
            "messageId": msgPayload["messageId"],
            "userId": userId,
            "content": msgPayload["content"],
            "timestamp": DateTime.now().toIso8601String(),
            "deleteReason": null,
          });
        }
      });
    } catch (e) {
      print("WebSocket connection error: $e");
    }
  }

  void sendMessage(String content) {
    if (_socket == null) {
      print("Socket chưa được khởi tạo.");
      return;
    }

    final message = {
      "type": "sendChat",
      "chatId": chatId,
      "messagePayload": {
        "type": "text",
        "content": content,
      },
    };

    try {
      _socket!.add(jsonEncode(message));
    } catch (e) {
      print("Lỗi khi gửi message: $e");
    }
  }


  void close() {
    _socket?.close();
  }
}
