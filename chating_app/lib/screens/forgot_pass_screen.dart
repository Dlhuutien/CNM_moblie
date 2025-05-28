import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:chating_app/services/env_config.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  String _message = '';
  bool _isLoading = false;

  // String _generateRandomPassword({int length = 10}) {
  //   const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#\$%';
  //   final rand = Random();
  //   return List.generate(length, (index) => chars[rand.nextInt(chars.length)]).join();
  // }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _message = "Please enter your email.".tr();
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      //Lấy userId từ email
      final getUserResponse = await http.get(
        Uri.parse('${EnvConfig.baseUrl}/user/account?email=$email'),
      );

      if (getUserResponse.statusCode != 200) {
        setState(() {
          _message = "User not found".tr();
          _isLoading = false;
        });
        return;
      }

      final userData = jsonDecode(getUserResponse.body);
      print("userData: $userData");
      // final userId = userData['userId'];
      final user = userData[0];
      final userId = user['id'];

      //Tạo mật khẩu mới
      // final newPassword = _generateRandomPassword();
      final newPassword = "newPassword@123";

      //Gửi API để đặt lại mật khẩu
      final resetResponse = await http.post(
        Uri.parse('${EnvConfig.baseUrl}/user/resetpassword'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'newPassword': newPassword,
        }),
      );

      final resetResult = jsonDecode(resetResponse.body);
      if (resetResponse.statusCode == 200 && resetResult['ok'] == 1) {
        //Gửi email thông báo người dùng
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

        setState(() {
          _message = "Password reset successfully. Check your email.".tr();
        });

        print("New password: $newPassword");
      } else {
        setState(() {
          _message = resetResult['message'] ?? "Failed to reset password".tr();
        });
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        _message = "An error occurred. Please try again later.".tr();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Future<void> _resetPassword() async {
  //   try {
  //     await FirebaseAuth.instance.sendPasswordResetEmail(
  //       email: _emailController.text.trim(),
  //     );
  //     setState(() {
  //       _message = "Password reset email has been sent!".tr();
  //     });
  //   } on FirebaseAuthException catch (e) {
  //     print("Firebase error: ${e.code} - ${e.message}");
  //     String error = "Failed to send password reset email.".tr();
  //     if (e.code == 'user-not-found') {
  //       error = "No user found with this email.".tr();
  //     } else if (e.code == 'invalid-email') {
  //       error = "Invalid email address".tr();
  //     }
  //     setState(() {
  //       _message = error;
  //     });
  //   } catch (e) {
  //     setState(() {
  //       _message = "An error occurred. Please try again later.".tr();
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text("Forgot Password").tr(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          reverse: true,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "Enter your email to reset password:",
                          style: TextStyle(fontSize: 16),
                        ).tr(),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: "Email",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _resetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Send reset email",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ).tr(),
                        ),
                        const SizedBox(height: 20),
                        if (_message.isNotEmpty)
                          Text(
                            _message,
                            style: const TextStyle(color: Colors.blue),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
