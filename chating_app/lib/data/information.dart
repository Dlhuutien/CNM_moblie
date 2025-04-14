import 'dart:convert';
import 'package:chating_app/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'user.dart';

class ApiService {
  static Future<ObjectUser?> login(
      BuildContext context, String phone, String password) async {
    try {
      final url = Uri.parse("http://138.2.106.32/user/login");
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'password': password}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        ObjectUser userData = ObjectUser(
          userID: data['id'].toString(),
          soDienThoai: data['phone'] ?? "",
          matKhau: data["password"] ?? "",
          hoTen: data["name"] ?? "",
          gender: "Nam",
          birthday: data["birthday"] ?? "",
          email: data['email'] ?? '',
          work: "",
        );

        return userData;
      } else {
        final data = jsonDecode(res.body);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Lỗi"),
            content: Text(data['message']),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
              )
            ],
          ),
        );
        return null;
      }
    } catch (e) {
      print("Error logging in: $e");
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Lỗi"),
          content: Text("Đăng nhập thất bại. Vui lòng thử lại."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            )
          ],
        ),
      );
      return null;
    }
  }
}

class ApiServiceSignUp {
  static Future<void> register(
      BuildContext context, String name, String phone, String password) async {
    try {
      final url = Uri.parse("http://138.2.106.32/user/signup"); // URL thật
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'phone': phone, 'password': password}),
      );

      if (res.statusCode == 200) {
        // Đăng ký thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đăng ký thành công!')),
        );
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        final data = jsonDecode(res.body);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Lỗi"),
            content: Text(data['message']),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print("Error registering: $e");
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Lỗi"),
          content: Text("Đăng ký thất bại. Vui lòng thử lại."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );
    }
  }
}
