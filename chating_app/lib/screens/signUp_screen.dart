import 'package:chating_app/data/information.dart';
import 'package:flutter/material.dart';

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



  void _signUp() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        errorMessage = null; // Reset error message
      });

      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() {
          errorMessage = 'Password does not match';
        });
        return;
      }

      // Tiến hành đăng ký (gửi request API)
      // print("User signed up: ${_nameController.text}");
      ApiServiceSignUp.register(
        context,
        _nameController.text,
        _phoneController.text,
        _passwordController.text,
      );

      // Sau khi đăng ký thành công, bạn có thể điều hướng đến màn hình chính
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign Up successful for ${_nameController.text}')),
      );

      // Ví dụ điều hướng về màn hình đăng nhập
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() {
        errorMessage = 'Please fill in all fields correctly';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
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
              _buildTextField(
                'Enter your phone number',
                _phoneController,
                Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              _buildTextField(
                'Enter your password',
                _passwordController,
                Icons.lock,
                obscureText: true,
              ),
              _buildTextField(
                'Confirm your password',
                _confirmPasswordController,
                Icons.lock,
                obscureText: true,
              ),
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
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: Text(
                  'Already have an account? Login',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
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
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller,
      IconData icon, {
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
          if (value == null || value.isEmpty) {
            return '$hint is required';
          }
          if (hint == 'Enter your phone number' && value.length < 10) {
            return 'Phone number must be at least 10 digits';
          }
          if (hint == 'Enter your password' && value.length < 8) {
            return 'Password must be at least 8 characters';
          }
          return null;
        },
      ),
    );
  }
}
