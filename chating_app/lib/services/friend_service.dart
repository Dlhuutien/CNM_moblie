import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:chating_app/services/env_config.dart';

class FriendService {
  static String get baseUrl => EnvConfig.baseUrl;

  static Future<String> sendFriendRequest(String currentUserId, int contactId) async {
    try {
      final response = await http.post(
        Uri.parse("${EnvConfig.baseUrl}/contact/add?userId=$currentUserId&contactId=$contactId"),
      );
      final res = json.decode(response.body);
      return res['message'] ?? "Friend request sent";
    } catch (e) {
      return "Error sending invitation: $e";
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

  /// Lấy và nhóm danh sách bạn bè theo chữ cái đầu
  static Future<Map<String, List<Map<String, dynamic>>>> getGroupedFriends(String userId) async {
    final response = await http.get(Uri.parse("$baseUrl/contact/list?userId=$userId"));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<Map<String, dynamic>> sorted =
      List<Map<String, dynamic>>.from(data['data']);

      sorted.sort((a, b) {
        final nameA = (a['name'] ?? '').toLowerCase();
        final nameB = (b['name'] ?? '').toLowerCase();
        return nameA.compareTo(nameB);
      });

      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (var friend in sorted) {
        final name = friend['name'] ?? '';
        final letter = name.isNotEmpty ? name[0].toUpperCase() : '#';
        grouped.putIfAbsent(letter, () => []).add(friend);
      }

      return grouped;
    } else {
      throw Exception("Lỗi khi lấy danh sách bạn bè: ${response.body}");
    }
  }
  /// Xóa bạn bè
  static Future<bool> unfriendContact(String userId, String contactId) async {
    final url = Uri.parse("$baseUrl/contact/unfriend?userId=$userId&contactId=$contactId");
    final response = await http.post(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } else if (response.statusCode == 404) {
      final data = jsonDecode(response.body);
      print("Lỗi: ${data['message']}");
      return false;
    } else {
      print("Lỗi không xác định khi xóa liên hệ: ${response.body}");
      return false;
    }
  }
  /// Lấy danh sách lời mời kết bạn
  static Future<List<Map<String, dynamic>>> fetchRequests(String userId) async {
    final url = Uri.parse("$baseUrl/contact/requests?userId=$userId");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      throw Exception("Lỗi khi lấy danh sách lời mời kết bạn: ${response.body}");
    }
  }
  /// Chấp nhận lời mời kết bạn
  static Future<bool> acceptRequest(String userId, String senderId) async {
    final url = Uri.parse("$baseUrl/contact/accept?userId=$userId&senderId=$senderId");
    final response = await http.post(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return true;
    } else {
      print("Lỗi khi chấp nhận lời mời: ${response.body}");
      return false;
    }
  }
  /// Từ chối lời mời kết bạn
  static Future<bool> denyRequest(String userId, String senderId) async {
    final url = Uri.parse("$baseUrl/contact/deny?userId=$userId&senderId=$senderId");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print("Lỗi khi từ chối lời mời: ${response.statusCode} - ${response.body}");
      return false;
    }
  }

}
