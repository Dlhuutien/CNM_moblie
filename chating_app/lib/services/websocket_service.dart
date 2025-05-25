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

        print("Raw data: ${jsonEncode(decoded)}");

        final type = decoded['type'];
        print("Type nhận được từ server: $type");

        if (type == "receiveChat") {
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
              "replyTo": msg["replyTo"] != null && msg["replyTo"] is Map
                  ? {
                "messageId": msg["replyTo"]["messageId"],
                "content": msg["replyTo"]["content"],
                "userId": msg["replyTo"]["userId"],
                "senderName": msg["replyTo"]["senderName"],
                "senderImage": msg["replyTo"]["senderImage"] ?? "",
              }
                  : msg["replyTo"] is String
                  ? {
                "messageId": msg["replyTo"],
              }
                  : null,

            });
          }
        } else if (type == "changeMessageType") {
          final msgId = decoded["msgId"];
          final deleteType = decoded["deleteType"];
          onMessage({
            "type": "change",
            "msgId": msgId,
            "deleteType": deleteType,
          });
        } else if (type == "ok" && decoded["originalType"] == "sendChat") {
          print("Tin nhắn gửi thành công: ${jsonEncode(decoded)}");
          final msgPayload = decoded["messagePayload"];
          print("Response messagePayload: $msgPayload");
          onMessage({
            "messageId": msgPayload["messageId"],
            "userId": userId,
            "content": msgPayload["content"],
            "attachmentUrl": msgPayload["attachmentUrl"],
            "timestamp": msgPayload["timestamp"],
            "deleteReason": null,
            "senderName": msgPayload["senderName"] ?? "",
            "senderImage": msgPayload["senderImage"] ?? "",
            "replyTo": msgPayload["replyTo"] != null ? msgPayload["replyTo"] : null,
          });
        }
      });
    } catch (e) {
      print("WebSocket connection error: $e");
    }
  }

  /// Gửi message text, hỗ trợ reply
  void sendMessage(
      String content,
      String senderName,
      String senderImage, {
        Map<String, dynamic>? replyToMessage,
        bool isForward = false,
      }) {
    if (_socket == null) {
      print("Socket chưa được khởi tạo.");
      return;
    }

    final Map<String, dynamic> messagePayload = {
      "type": "text",
      "content": content,
      "senderName": senderName,
      "senderImage": senderImage,
    };

    // Gửi replyTo đúng theo backend (chỉ cần messageId)
    if (replyToMessage != null && replyToMessage["messageId"] != null) {
      messagePayload["replyTo"] = replyToMessage["messageId"];
    }

    if (isForward) {
      messagePayload["isForward"] = true;
    }

    final message = {
      "type": "sendChat",
      "chatId": chatId,
      "messagePayload": messagePayload,
    };

    try {
      final jsonString = jsonEncode(message);
      print("Gửi message: $jsonString");
      _socket!.add(jsonString);
    } catch (e) {
      print("Lỗi khi gửi message: $e");
    }
  }

  /// Gửi message có đính kèm attachment, hỗ trợ forward
  void sendMessageWithAttachment({
    required String content,
    required String attachmentUrl,
    bool isForward = false,  // thêm param isForward
  }) {
    if (_socket == null) {
      print("Socket chưa được khởi tạo.");
      return;
    }

    final messagePayload = {
      "type": "attachment",
      "content": content,
      "attachmentUrl": attachmentUrl,
    };

    if (isForward) {
      messagePayload["isForward"] = "true";  // thêm field isForward khi cần
    }

    final message = {
      "type": "sendChat",
      "chatId": chatId,
      "messagePayload": messagePayload,
    };

    try {
      _socket!.add(jsonEncode(message));
    } catch (e) {
      print("Lỗi khi gửi message đính kèm: $e");
    }
  }

  /// Đóng kết nối socket
  void close() {
    _socket?.close();
  }
}
