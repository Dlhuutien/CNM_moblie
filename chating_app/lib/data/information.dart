import 'dart:convert';
import 'package:chating_app/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'user.dart';

class ApiService {
  static Future<ObjectUser?> login(BuildContext context, String phone, String password) async {
    try {
      final url = Uri.parse("http://138.2.106.32/user/login");
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'password': password}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return ObjectUser(
          userID: data['id'].toString(),
          soDienThoai: data['phone'] ?? "",
          matKhau: data["password"] ?? "",
          hoTen: data["name"] ?? "",
          gender: "Nam",
          birthday: data["birthday"] ?? "",
          email: data['email'] ?? '',
          work: "",
          image: data["image"] ?? "",
          location: data["location"] ?? "",
        );
      } else {
        final data = jsonDecode(res.body);
        _showErrorDialog(context, data['message']);
        return null;
      }
    } catch (e) {
      print("Error logging in: $e");
      _showErrorDialog(context, "Đăng nhập thất bại. Vui lòng thử lại.");
      return null;
    }
  }

  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Lỗi"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}

class ApiServiceSignUp {
  /// Trả về `true` nếu đăng ký thành công, `false` nếu thất bại
  static Future<bool> register(BuildContext context, String name, String phone, String password) async {
    try {
      final url = Uri.parse("http://138.2.106.32/user/signup");
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'phone': phone, 'password': password}),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['ok'] == 1) {
        return true;
      } else {
        _showErrorDialog(context, data['message'] ?? 'Đăng ký thất bại');
        return false;
      }
    } catch (e) {
      print("Error registering: $e");
      _showErrorDialog(context, "Đăng ký thất bại. Vui lòng thử lại.");
      return false;
    }
  }

  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Lỗi"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
