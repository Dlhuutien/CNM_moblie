import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? errorMessage;

  void _signUp() {
    setState(() {
      errorMessage = null; // Reset error message
      if (_phoneController.text.isEmpty) {
        errorMessage = 'Phone number is required';
      } else if (_passwordController.text != _confirmPasswordController.text) {
        errorMessage = 'Password does not match';
      } else if (_passwordController.text.length < 8) {
        errorMessage =
        'Password must include at least 8 characters, 1 uppercase letter, 1 number, and 1 special character';
      } else {
        // Thực hiện đăng ký ở đây
        // Ví dụ: Hiển thị thông báo thành công hoặc lưu dữ liệu người dùng
        print("User signed up: ${_nameController.text}");
        // Sau khi đăng ký thành công, bạn có thể quay lại màn hình đăng nhập hoặc làm gì đó khác
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign Up successful for ${_nameController.text}')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
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
            _buildTextField(
                'Enter your phone number', _phoneController, Icons.phone),
            _buildTextField(
                'Enter your password', _passwordController, Icons.lock,
                obscureText: true),
            _buildTextField('Confirm your password',
                _confirmPasswordController, Icons.lock, obscureText: true),
            if (errorMessage != null) ...[
              SizedBox(height: 10),
              Text(
                errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
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
            Text('Already have an account? Login'),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.facebook, color: Colors.blue),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.g_mobiledata, color: Colors.red),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller,
      IconData icon, {bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
