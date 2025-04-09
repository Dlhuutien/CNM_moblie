import 'dart:convert';

import 'package:chating_app/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'user.dart';

class LoginData {
  static List<ObjectUser> users = [
    ObjectUser(
      soDienThoai: '0386474751',
      matKhau: 'huutien123',
      hoTen: 'Đặng Lê Hữu Tiến',
      gender: 'Male',
      birthday: '29/08/2003',
      email: 'tien@gmail.com',
      work: 'Mobile Developer',
    ),
    ObjectUser(
      soDienThoai: '0911223344',
      matKhau: 'abc123',
      hoTen: 'Nguyễn Văn A',
      gender: 'Male',
      birthday: '01/01/2000',
      email: 'vana@gmail.com',
      work: 'Backend Developer',
    ),
    ObjectUser(
      soDienThoai: '0987654321',
      matKhau: 'hello123',
      hoTen: 'Trần Thị B',
      gender: 'Female',
      birthday: '20/05/1998',
      email: 'thiB@gmail.com',
      work: 'UI/UX Designer',
    ),
  ];

// Hàm kiểm tra đăng nhập
//   static ObjectUser? login(String phone, String pass) {
//
//     try {
//       return users.firstWhere(
//             (user) => user.soDienThoai == phone && user.matKhau == pass,
//       );
//     } catch (e) {
//       return null;
//     }
// }
}

// import 'package:shared_preferences/shared_preferences.dart'; // lưu local
class ApiService {
  static Future<void> login(
      BuildContext context, String phone, String password) async {
    try {
      final url =
          Uri.parse("http://138.2.106.32/user/login"); // thay URL thật vào đây
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'password': password}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        ObjectUser userData = new ObjectUser(
            soDienThoai: data['phone'] ?? "",
            matKhau: data["password"] ?? "",
            hoTen: data["name"] ?? "",
            gender: "Nam",
            birthday: data["birthday"] ?? "",
            email: "",
            work: "");
        if (data['email'] == null) {
          // Navigator.pushReplacementNamed(context, '/signup/success', arguments: {'id': data['id']});
          Navigator.push(
              context,
              MaterialPageRoute(
                  // builder: (context) => ProfileScreen(user: user),
                  builder: (context) => MainScreen(user: userData)));
        } else {
          // SharedPreferences prefs = await SharedPreferences.getInstance();
          // prefs.setString('user', jsonEncode(data)); // nếu muốn lưu local

          Navigator.pushReplacementNamed(context, '/');
        }
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
