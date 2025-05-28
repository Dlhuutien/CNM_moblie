import 'package:chating_app/data/information.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:chating_app/services/env_config.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:chating_app/screens/update_profile_signup.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  String? errorMessage;

  Future<bool> _isPhoneExists(String phone) async {
    final url = Uri.parse('${EnvConfig.baseUrl}/user/account?phone=$phone');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List && data.isNotEmpty;
    }
    return false;
  }

  void _signUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => errorMessage = null);

      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() => errorMessage = 'Password does not match'.tr());
        return;
      }

      final phoneExists = await _isPhoneExists(_phoneController.text);
      if (phoneExists) {
        setState(() => errorMessage = 'Phone number already exists'.tr());
        return;
      }

      final success = await ApiServiceSignUp.register(
        context,
        _nameController.text,
        _phoneController.text,
        _passwordController.text,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content:
          Text('Sign up successfull'.tr())
          ),
        );

        // Future.delayed(const Duration(milliseconds: 800), () {
        //   Navigator.pushReplacementNamed(context, '/login');
        // });
        Future.delayed(const Duration(milliseconds: 800), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => UpdateProfileSignUp(
                name: _nameController.text,
                phone: _phoneController.text,
              ),
            ),
          );
        });
      }
    } else {
      setState(() => errorMessage = 'Please fill in all fields correctly'.tr());
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
                        "SIGN UP",
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
                            _buildTextField('Enter your name'.tr(), _nameController, Icons.person, fieldType: 'name'),
                            _buildTextField('Enter your phone number'.tr(), _phoneController, Icons.phone, keyboardType: TextInputType.phone, fieldType: 'phone'),
                            _buildTextField('Enter your password'.tr(), _passwordController, Icons.lock, obscureText: true, fieldType: 'password'),
                            _buildTextField('Confirm your password'.tr(), _confirmPasswordController, Icons.lock, obscureText: true, fieldType: 'password'),
                            if (errorMessage != null) ...[
                              const SizedBox(height: 10),
                              Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                            ],
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _signUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                "Sign Up",
                                style: TextStyle(fontSize: 18, color: Colors.white),
                              ).tr(),
                            ),
                            const SizedBox(height: 20),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(context, '/login');
                              },
                              child: const Text('Already have an account? Login', style: TextStyle(color: Colors.blue)).tr(),
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

  Widget _buildTextField(String hint, TextEditingController controller, IconData icon, {
    required String fieldType,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText ? _obscurePassword : false,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          hintText: hint,
          border: const UnderlineInputBorder(),
          errorStyle: const TextStyle(
            fontSize: 13,
            height: 1.4,
            overflow: TextOverflow.visible,
          ),
          errorMaxLines: 3,
          suffixIcon: obscureText
              ? IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          )
              : null,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '$hint is required'.tr();
          }

          switch (fieldType) {
            case 'name':
              if (!RegExp(r"^([A-ZÀ-Ỵ][a-zà-ỵ]+)( [A-ZÀ-Ỵ][a-zà-ỵ]+)*$", unicode: true).hasMatch(value.trim())) {
                return 'Name must be capitalized and must not contain special characters'.tr();
              }
              break;
            case 'phone':
              if (!RegExp(r"^\d{10}$").hasMatch(value.trim())) {
                return 'Phone number must be exactly 10 digits'.tr();
              }
              break;
            case 'password':
              if (!RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*(),.?":{}|<>])[^\s]{8,16}$').hasMatch(value)) {
                return 'Password must be 8-16 characters, include at least 1 uppercase letter, 1 number, and 1 special character, with no spaces'.tr();
              }
              break;
          }

          return null;
        },
      ),
    );
  }
}
