import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  String _message = '';

  Future<void> _resetPassword() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      setState(() {
        _message = "Đã gửi email khôi phục mật khẩu. Kiểm tra hộp thư của bạn!";
      });
    } on FirebaseAuthException catch (e) {
      print("Firebase error: ${e.code} - ${e.message}"); // In lỗi cụ thể
      String error = "Không thể gửi email khôi phục. Vui lòng kiểm tra lại email!";
      if (e.code == 'user-not-found') {
        error = "Không tìm thấy người dùng với email này.";
      } else if (e.code == 'invalid-email') {
        error = "Email không hợp lệ.";
      }
      setState(() {
        _message = error;
      });
    } catch (e) {
      print("Lỗi không xác định: $e");
      setState(() {
        _message = "Đã xảy ra lỗi. Vui lòng thử lại sau.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quên Mật Khẩu")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Nhập email để khôi phục mật khẩu:",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _resetPassword,
              child: const Text("Gửi email khôi phục"),
            ),
            const SizedBox(height: 20),
            Text(
              _message,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
