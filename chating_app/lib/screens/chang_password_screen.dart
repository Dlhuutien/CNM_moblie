import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:chating_app/services/env_config.dart';
import 'package:easy_localization/easy_localization.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String? phone;

  const ChangePasswordScreen({super.key, this.phone});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _isHidden = true;
  bool _isLoading = false;
  String _message = '';

  Future<bool> _checkOldPassword() async {
    final url = Uri.parse('${EnvConfig.baseUrl}/user/account?phone=${widget.phone}');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List && data.isNotEmpty) {
        final user = data[0];
        final storedPassword = user["password"];
        if (storedPassword == _oldPassController.text.trim()) {
          return true;
        }
      }
    }
    setState(() {
      _message = "Current password is incorrect.".tr();
    });
    return false;
  }

  Future<void> _changePassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_newPassController.text != _confirmPassController.text) {
        setState(() {
          _message = 'Password confirmation does not match'.tr();
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _message = '';
      });

      // Kiểm tra mật khẩu cũ trước
      bool isOldPassCorrect = await _checkOldPassword();
      if (!isOldPassCorrect) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      try {
        final response = await http.post(
          Uri.parse("${EnvConfig.baseUrl}/user/changepass"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "phone": widget.phone,
            "oldpassword": _oldPassController.text.trim(),
            "newpassword": _newPassController.text.trim(),
          }),
        );

        final result = jsonDecode(response.body);
        if (result["ok"] == 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Password changed successfully!".tr())),
          );
          Navigator.pop(context);
        } else {
          setState(() {
            _message = result["message"] ?? "An error occurred.".tr();
          });
        }
      } catch (e) {
        setState(() {
          _message = "Failed to connect to server.".tr();
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildPasswordField(String label, TextEditingController controller, {bool isNewPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: _isHidden,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.lock),
          border: const OutlineInputBorder(),
          errorStyle: const TextStyle(
            fontSize: 13,
            height: 1.4,
            overflow: TextOverflow.visible,
          ),
          errorMaxLines: 3,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return '$label is required'.tr();

          if (isNewPassword) {
            if (!RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*(),.?":{}|<>])[^\s]{8,16}$').hasMatch(value)) {
              return 'Password must be 8-16 characters, include at least 1 uppercase letter, 1 number, and 1 special character, with no spaces'.tr();
            }
          }

          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text("Change Password").tr(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          reverse: true,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "Please enter your current and new password:",
                        style: TextStyle(fontSize: 16),
                      ).tr(),
                      const SizedBox(height: 16),
                      if (_isLoading) const LinearProgressIndicator(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => setState(() => _isHidden = !_isHidden),
                            child: Text(_isHidden ? "Show".tr() : "Hide".tr()),
                          ),
                        ],
                      ),
                      _buildPasswordField("Current Password".tr(), _oldPassController, isNewPassword: false),
                      _buildPasswordField("New Password".tr(), _newPassController, isNewPassword: true),
                      _buildPasswordField("Confirm New Password".tr(), _confirmPassController, isNewPassword: true),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Change Password",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ).tr(),
                      ),
                      const SizedBox(height: 20),
                      if (_message.isNotEmpty)
                        Text(
                          _message,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
