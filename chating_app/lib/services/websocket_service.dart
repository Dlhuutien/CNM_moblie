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

      print("Đã gửi joinChat với chatId: $chatId");

      // Lắng nghe tin nhắn từ server
      _socket?.listen((data) {
        final decoded = jsonDecode(data);

        print("📦 raw data: ${jsonEncode(decoded)}");

        final type = decoded['type'];
        print("Type nhận được từ server: $type");
        print("Đã nhận được receiveChat: ${jsonEncode(decoded)}");
        if (decoded["type"] == "receiveChat") {
          print("receiveChat full: ${jsonEncode(decoded)}");

          final msg = decoded["message"];
          final incomingChatId = decoded["chatId"] ?? msg["chatId"];

          print("Nhận được message từ chatId: $incomingChatId, hiện tại: $chatId");

          if (incomingChatId == chatId) {
            onMessage({
              "messageId": msg["messageId"],
              "userId": msg["senderId"],
              "content": msg["content"],
              "type": msg["type"],
              "attachmentUrl": msg["attachmentUrl"],
              "timestamp": msg["timestamp"],
              "senderName": msg["senderName"],
              "senderImage": msg["senderImage"],
              "deleteReason": msg["deleteReason"],
            });
          }
        }
        else if (decoded["type"] == "changeMessageType") {
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
            "attachmentUrl": msgPayload["attachmentUrl"],
            "timestamp": msgPayload["timestamp"],
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

  void sendMessageWithAttachment({
    required String content,
    required String attachmentUrl,
  }) {
    if (_socket == null) {
      print("Socket chưa được khởi tạo.");
      return;
    }

    final message = {
      "type": "sendChat",
      "chatId": chatId,
      "messagePayload": {
        "type": "attachment",
        "content": content,
        "attachmentUrl": attachmentUrl,
      },
    };

    try {
      _socket!.add(jsonEncode(message));
    } catch (e) {
      print("Lỗi khi gửi message đính kèm: $e");
    }
  }



  void close() {
    _socket?.close();
  }
}
