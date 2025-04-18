import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  String _message = '';
  bool _isLoading = false;

  // Gọi API đổi mật khẩu
  Future<void> _changePassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_newPassController.text != _confirmPassController.text) {
        setState(() {
          _message = 'Mật khẩu xác nhận không khớp';
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _message = '';
      });

      try {
        print("Số điện thoại: ${widget.phone}");
        print("Mật khẩu cũ: ${_oldPassController.text.trim()}");
        print("Mật khẩu mới: ${_newPassController.text.trim()}");
        final response = await http.post(
          Uri.parse("http://138.2.106.32/user/changepass"),
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
            const SnackBar(content: Text("Đổi mật khẩu thành công!")),
          );
          Navigator.pop(context);
        } else {
          setState(() {
            _message = result["message"] ?? "Có lỗi xảy ra";
          });
        }
      } catch (e) {
        setState(() {
          _message = "Không thể kết nối đến máy chủ";
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTextField(String hint, TextEditingController controller,
      {bool obscure = false, TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: hint,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return '$hint là bắt buộc';
          if (hint.contains('Mật khẩu') && value.length < 8) return 'Mật khẩu phải >= 8 ký tự';
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Đổi Mật Khẩu")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_isLoading) const LinearProgressIndicator(),

              // Đổi mật khẩu
              _buildTextField("Mật khẩu hiện tại", _oldPassController, obscure: true),
              _buildTextField("Mật khẩu mới", _newPassController, obscure: true),
              _buildTextField("Xác nhận mật khẩu", _confirmPassController, obscure: true),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _changePassword,
                child: const Text("Đổi mật khẩu"),
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
    );
  }
}
