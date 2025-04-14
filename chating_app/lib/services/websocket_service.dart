// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/foundation.dart';
//
// typedef OnMessageReceived = void Function(Map<String, dynamic> message);
//
// class WebSocketService {
//   late WebSocket _socket;
//   final String userId;
//   final String chatId;
//   final OnMessageReceived onMessage;
//
//   WebSocketService({
//     required this.userId,
//     required this.chatId,
//     required this.onMessage,
//   });
//
//   Future<void> connect() async {
//     try {
//       _socket = await WebSocket.connect("ws://138.2.106.32/ws");
//
//       _socket.add(jsonEncode({
//         "type": "joinSocket",
//         "userID": userId,
//       }));
//
//       _socket.add(jsonEncode({
//         "type": "joinChat",
//         "chatId": chatId,
//       }));
//
//       _socket.listen((data) {
//         final message = jsonDecode(data);
//         if (message["type"] == "receiveChat") {
//           onMessage(message["message"]);
//         }
//       });
//     } catch (e) {
//       if (kDebugMode) {
//         print("WebSocketService connection error: $e");
//       }
//     }
//   }
//
//   void sendMessage(String content) {
//     final message = {
//       "type": "sendChat",
//       "chatId": chatId,
//       "messagePayload": {
//         "type": "text",
//         "content": content,
//       }
//     };
//     _socket.add(jsonEncode(message));
//   }
//
//   void close() {
//     _socket.close();
//   }
// }
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
        }
      });
    } catch (e) {
      print("WebSocket connection error: $e");
    }
  }

  // void sendMessage(String content) {
  //   final message = {
  //     "type": "sendChat",
  //     "chatId": chatId,
  //     "messagePayload": {
  //       "type": "text",
  //       "content": content,
  //     },
  //   };
  //
  //   if (_socket != null) {
  //     _socket!.add(jsonEncode(message));
  //   } else {
  //     print("Socket chưa được khởi tạo.");
  //   }
  // }
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
