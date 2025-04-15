import 'package:chating_app/data/information.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? errorMessage;

  Future<bool> _isPhoneExists(String phone) async {
    final url = Uri.parse('http://138.2.106.32/user/account?phone=$phone');
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
        setState(() => errorMessage = 'Password does not match');
        return;
      }

      final phoneExists = await _isPhoneExists(_phoneController.text);
      if (phoneExists) {
        setState(() => errorMessage = 'Phone number already exists');
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
          const SnackBar(content: Text('Đăng ký thành công!')),
        );

        Future.delayed(const Duration(milliseconds: 800), () {
          Navigator.pushReplacementNamed(context, '/login');
        });
      }
    } else {
      setState(() => errorMessage = 'Please fill in all fields correctly');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          reverse: true,
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'SIGN UP',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 20),
                _buildTextField('Enter your name', _nameController, Icons.person),
                _buildTextField('Enter your phone number', _phoneController, Icons.phone, keyboardType: TextInputType.phone),
                _buildTextField('Enter your password', _passwordController, Icons.lock, obscureText: true),
                _buildTextField('Confirm your password', _confirmPasswordController, Icons.lock, obscureText: true),
                if (errorMessage != null) ...[
                  SizedBox(height: 10),
                  Text(errorMessage!, style: TextStyle(color: Colors.red)),
                ],
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _signUp,
                  child: Text('Sign Up'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: Text('Already have an account? Login', style: TextStyle(color: Colors.blue)),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(icon: Icon(Icons.facebook, color: Colors.blue), onPressed: () {}),
                    IconButton(icon: Icon(Icons.g_mobiledata, color: Colors.red), onPressed: () {}),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, IconData icon, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '$hint is required';
          }
          if (hint == 'Enter your name') {
            if (!RegExp(r"^([A-ZÀ-Ỵ][a-zà-ỵ]+)( [A-ZÀ-Ỵ][a-zà-ỵ]+)*$", unicode: true).hasMatch(value.trim())) {
              return 'Tên phải viết hoa chữ cái đầu và không chứa ký tự đặc biệt';
            }
          }

          if (hint == 'Enter your phone number') {
            if (!RegExp(r"^\d{10}$").hasMatch(value.trim())){
              return 'Phone number must be exactly 10 digits';
            }
          }
          if (hint == 'Enter your password') {
            if (!RegExp(r'^[\S]{8,16}$').hasMatch(value)) {
              return 'Password must be 8-16 characters, no spaces';
            }
          }
          return null;
        },
      ),
    );
  }
}
