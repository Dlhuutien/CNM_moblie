import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:easy_localization/easy_localization.dart';
import 'package:chating_app/services/env_config.dart';

class UpdateProfileSignUp extends StatefulWidget {
  final String name;
  final String phone;

  const UpdateProfileSignUp({super.key, required this.name, required this.phone});

  @override
  State<UpdateProfileSignUp> createState() => _UpdateProfileSignUpState();
}

class _UpdateProfileSignUpState extends State<UpdateProfileSignUp> {
  final _formKey = GlobalKey<FormState>();
  final _birthdayController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime? _selectedBirthday;

  String? errorMessage;

  Future<bool> _isEmailExists(String email) async {
    final url = Uri.parse('${EnvConfig.baseUrl}/user/account?email=$email');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List && data.isNotEmpty;
    }
    return false;
  }

  Future<int?> _getUserIdByPhone(String phone) async {
    final url = Uri.parse('${EnvConfig.baseUrl}/user/account?phone=$phone');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List && data.isNotEmpty) {
        // Lấy user có id != 0, hoặc user đầu tiên
        final user = data.firstWhere((u) => u['id'] != 0, orElse: () => data[0]);
        return user['id'] as int?;
      }
    }
    return null;
  }

  void _submitProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => errorMessage = null);

      final emailExists = await _isEmailExists(_emailController.text);
      if (emailExists) {
        setState(() => errorMessage = 'Email already exists'.tr());
        return;
      }

      final userId = await _getUserIdByPhone(widget.phone);
      if (userId == null) {
        setState(() => errorMessage = 'User not found'.tr());
        return;
      }

      final url = Uri.parse("${EnvConfig.baseUrl}/user/update");
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "id": userId,
          "name": widget.name,
          "phone": widget.phone,
          "email": _emailController.text.trim(),
          "birthday": _selectedBirthday?.toUtc().toIso8601String(),
          "location": _locationController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully'.tr())),
        );

        Navigator.pushReplacementNamed(context, '/login');
      } else {
        setState(() => errorMessage = 'Update failed: ${response.body}');
      }
    } else {
      setState(() => errorMessage = 'Please fill in all fields correctly'.tr());
    }
  }

  String _formatDateOnly(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (_) {
      return isoDate;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          reverse: true,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                      color: Colors.blue,
                      alignment: Alignment.center,
                      child: const Text(
                        "COMPLETE PROFILE",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ).tr(),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildReadOnlyField("Your name", widget.name),
                            _buildReadOnlyField("Phone", widget.phone),
                            _buildTextField(
                              "Birthday",
                              _birthdayController,
                              Icons.cake,
                              readOnly: true,
                              onTap: () async {
                                FocusScope.of(context).requestFocus(FocusNode()); // ẩn bàn phím
                                DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // mặc định 18 tuổi
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  _selectedBirthday = picked;
                                  _birthdayController.text = _formatDateOnly(picked.toIso8601String());
                                }
                              },
                            ),
                            _buildTextField("Email", _emailController, Icons.email, keyboardType: TextInputType.emailAddress),
                            _buildTextField("Location", _locationController, Icons.location_on),
                            if (errorMessage != null) ...[
                              const SizedBox(height: 10),
                              Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                            ],
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _submitProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                "Submit",
                                style: TextStyle(fontSize: 18, color: Colors.white),
                              ).tr(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller,
      IconData icon, {
        TextInputType keyboardType = TextInputType.text,
        bool readOnly = false,
        VoidCallback? onTap,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label.tr(),
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '$label is required';
          }
          if (label == 'Email') {
            if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(value.trim())) {
              return 'Invalid email format'.tr();
            }
          }
          return null;
        },
      ),
    );
  }


  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        initialValue: value,
        readOnly: true,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.lock),
          hintText: label.tr(),
          border: const UnderlineInputBorder(),
        ),
      ),
    );
  }
}
