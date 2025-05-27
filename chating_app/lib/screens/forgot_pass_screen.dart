import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

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
        _message = "Password reset email has been sent!".tr();
      });
    } on FirebaseAuthException catch (e) {
      print("Firebase error: ${e.code} - ${e.message}");
      String error = "Failed to send password reset email.".tr();
      if (e.code == 'user-not-found') {
        error = "No user found with this email.".tr();
      } else if (e.code == 'invalid-email') {
        error = "Invalid email address".tr();
      }
      setState(() {
        _message = error;
      });
    } catch (e) {
      setState(() {
        _message = "An error occurred. Please try again later.".tr();
      });
    }
  }

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
