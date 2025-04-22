import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class ChatApi {
  static const String baseUrl = "http://138.2.106.32";

  ///Lấy các user đã nhắn tin
  static Future<List<Map<String, dynamic>>> fetchChatsWithLatestMessage(String userId) async {
    final response = await http.get(Uri.parse("$baseUrl/chat/me?userId=$userId"));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List chats = data["data"];
      List<Map<String, dynamic>> chatsWithMessages = [];

      for (var chat in chats) {
        final chatId = chat["ChatID"];
        final infoResponse = await http.get(Uri.parse("$baseUrl/chat/$chatId/info?userId=$userId"));

        if (infoResponse.statusCode == 200) {
          final infoData = json.decode(infoResponse.body);
          final latestMessage = infoData["data"]["latestMessage"];
          chat["latestMessage"] = latestMessage;
          chatsWithMessages.add(Map<String, dynamic>.from(chat));
        }
      }

      return chatsWithMessages;
    } else {
      throw Exception("Lỗi khi lấy danh sách chat: ${response.body}");
    }
  }


  ///Lấy lịch sử trò chuyện
  static Future<List<Map<String, dynamic>>> fetchMessages(String chatId, String userId) async {
    final url = Uri.parse("$baseUrl/chat/$chatId/history/50?userId=$userId");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      throw Exception("Lỗi fetchMessages: ${response.body}");
    }
  }

  ///Hiển thị profile của người đang trò chuyện
  static Future<Map<String, dynamic>> loadPartnerInfo(String chatId, String userId) async {
    final url = Uri.parse("$baseUrl/chat/$chatId/info?userId=$userId");
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final members = data['data']['members'] as List<dynamic>;

      final partner = members.firstWhere(
            (m) => m['userId'].toString() != userId,
        orElse: () => {},
      );

      return Map<String, dynamic>.from(partner);
    } else {
      throw Exception("Lỗi khi lấy thông tin partner: ${res.body}");
    }
  }

  ///Upload file
  static Future<Map<String, String>?> uploadFile(String filePath, String fileName) async {
    final url = Uri.parse('$baseUrl/user/upload');
    final mimeType = lookupMimeType(filePath);
    final request = http.MultipartRequest('POST', url);

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        filePath,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        filename: fileName,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['ok'] == 1) {
        return {
          "url": data['imageUrl'],
          "name": fileName,
        };
      } else {
        print("Lỗi từ server: ${data['message']}");
      }
    } else {
      print("Lỗi upload file: ${response.body}");
    }

    return null;
  }


  ///Upload file hình
  static Future<String?> uploadImage(XFile file) async {
    final url = Uri.parse('$baseUrl/user/upload');
    final request = http.MultipartRequest('POST', url);

    // Đồng bộ mime với backend
    final mimeType = lookupMimeType(file.path);

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        filename: "img_${DateTime.now().millisecondsSinceEpoch}.${file.path.split(".").last}",
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['ok'] == 1) {
        return data['imageUrl'];
      } else {
        print("Lỗi từ server: ${data['message']}");
        return null;
      }
    } else {
      print("Lỗi upload ảnh: ${response.body}");
      return null;
    }
  }


  ///Xóa tin nhắn
  static Future<bool> deleteMessage(String messageId, String deleteType) async {
    final url = Uri.parse("$baseUrl/chat/deleteMsg")
        .replace(queryParameters: {
      "messageId": messageId,
      "deleteType": deleteType,
    });

    final response = await http.post(url);
    if (response.statusCode == 200) {
      return true;
    } else {
      print("Lỗi khi xóa/thu hồi: ${response.body}");
      return false;
    }
  }

  ///Tìm kiếm tin nhắn
  static Future<List<Map<String, dynamic>>> searchMessages(String chatId, String query, String userId) async {
    final url = Uri.parse("$baseUrl/chat/$chatId/search?query=$query&userId=$userId");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      throw Exception("Lỗi searchMessages: ${response.body}");
    }
  }

  ///Lấy danh sách bạn bè
  static Future<List<Map<String, dynamic>>> getContacts(String userId) async {
    final url = Uri.parse("$baseUrl/contact/list?userId=$userId");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      throw Exception("Lỗi khi lấy danh sách bạn bè: ${response.body}");
    }
  }

  ///Thêm thành viên vào nhóm
  static Future<void> addGroupMember(String chatId, String userId, int newMemberId) async {
    final url = Uri.parse("$baseUrl/group/member/add");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "chatId": chatId,
        "userId": int.tryParse(userId),
        "newMemberId": newMemberId,
        "role": "member",
      }),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception("Lỗi khi thêm thành viên $newMemberId: ${data['message']}");
    }
  }


  /// Lấy danh sách thành viên nhóm
  static Future<List<Map<String, dynamic>>> getGroupMembers(String chatId, String userId) async {
    final url = Uri.parse("$baseUrl/group/$chatId/members?userId=$userId");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data["members"]);
    } else {
      throw Exception("Lỗi khi lấy danh sách thành viên: ${response.body}");
    }
  }

  /// Xóa thành viên khỏi nhóm
  static Future<void> removeGroupMember(String chatId, String userId, String memberToRemoveId) async {
    final url = Uri.parse("$baseUrl/group/member/remove");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "chatId": chatId,
        "userId": userId,
        "memberToRemoveId": memberToRemoveId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Lỗi khi xóa thành viên: ${response.body}");
    }
  }

  /// Rời khỏi nhóm
  static Future<void> leaveGroup(String chatId, String userId) async {
    final url = Uri.parse("$baseUrl/group/leave");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "chatId": chatId,
        "userId": int.tryParse(userId),
      }),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception("Lỗi rời nhóm: ${data['message']}");
    }
  }


  /// Thay đổi vai trò thành viên
  static Future<void> changeGroupRole(String chatId, String userId, String memberToChangeId, String newRole) async {
    final url = Uri.parse("$baseUrl/group/member/role");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "chatId": chatId,
        "userId": userId,
        "memberToChangeId": memberToChangeId,
        "newRole": newRole,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Lỗi khi thay đổi vai trò: ${response.body}");
    }
  }

  /// Giải tán nhóm
  static Future<void> disbandGroup(String chatId, String userId) async {
    final url = Uri.parse("$baseUrl/group/disband");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "chatId": chatId,
        // "userId": userId,
        "userId": int.tryParse(userId),
      }),
    );
    print("Gửi yêu cầu giải tán nhóm với chatId: $chatId, userId: $userId");
    if (response.statusCode != 200) {
      throw Exception("Lỗi khi giải tán nhóm: ${response.body}");
    }
  }
}

