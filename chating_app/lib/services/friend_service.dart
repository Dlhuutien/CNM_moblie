import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:chating_app/services/env_config.dart';

class FriendService {
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
}
