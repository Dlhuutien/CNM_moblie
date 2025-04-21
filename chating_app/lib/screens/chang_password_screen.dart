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

  bool _isHidden = true;
  bool _isLoading = false;
  String _message = '';

  Future<void> _changePassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_newPassController.text != _confirmPassController.text) {
        setState(() {
          _message = 'Password confirmation does not match.';
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _message = '';
      });

      try {
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
            const SnackBar(content: Text("Password changed successfully!")),
          );
          Navigator.pop(context);
        } else {
          setState(() {
            _message = result["message"] ?? "An error occurred.";
          });
        }
      } catch (e) {
        setState(() {
          _message = "Failed to connect to server.";
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: _isHidden,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.lock),
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return '$label is required';
          if (value.length < 8) return 'Password must be at least 8 characters';
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
        title: const Text("Change Password"),
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
                      ),
                      const SizedBox(height: 16),
                      if (_isLoading) const LinearProgressIndicator(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => setState(() => _isHidden = !_isHidden),
                            child: Text(_isHidden ? "Show" : "Hide"),
                          ),
                        ],
                      ),
                      _buildPasswordField("Current Password", _oldPassController),
                      _buildPasswordField("New Password", _newPassController),
                      _buildPasswordField("Confirm New Password", _confirmPassController),

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
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_message.isNotEmpty)
                        Text(
                          _message,
                          style: const TextStyle(color: Colors.blue),
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
