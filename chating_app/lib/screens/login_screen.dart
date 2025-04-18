import 'package:chating_app/data/user.dart';
import 'package:chating_app/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:chating_app/data/information.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chating_app/screens/forgot_pass_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _errorMessage = '';

  void _handleLogin() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    final phoneValid = RegExp(r'^\d{10}$').hasMatch(phone);
    final passwordValid = RegExp(r'^[\S]{8,16}$').hasMatch(password);

    if (!phoneValid) {
      setState(() {
        _errorMessage = 'Số điện thoại phải đúng 10 chữ số.';
      });
      return;
    }

    if (!passwordValid) {
      setState(() {
        _errorMessage = 'Mật khẩu 8-16 ký tự, không dấu cách.';
      });
      return;
    }

    ObjectUser? user = await ApiService.login(context, phone, password);

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen(user: user)),
      );
    } else {
      setState(() {
        _errorMessage = 'Số điện thoại hoặc mật khẩu không đúng!';
      });
    }
  }


  Future<void> _signInWithGoogle() async {
    try {
      // Bước 1: Hiển thị giao diện đăng nhập Google
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
          clientId: "19142047184-ul1hhcea8drflmk5jqokj5cu2aih2be9.apps.googleusercontent.com"
      ).signIn();
      if (googleUser == null) return; // Người dùng huỷ đăng nhập

      // Bước 2: Lấy thông tin xác thực
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Bước 3: Tạo credential để đăng nhập với Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Bước 4: Đăng nhập vào Firebase
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Tạo ObjectUser để đưa vào MainScreen
        ObjectUser newUser = ObjectUser(
          userID: "",
          soDienThoai: user.phoneNumber ?? '',
          password: '',
          hoTen: user.displayName ?? '',
          gender: 'Nam',
          birthday: '29/08/2003',
          email: user.email ?? '',
          work: 'Developer Software',
          image: "",
          location:"",
        );

        // Điều hướng sang màn hình chính
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen(user: newUser)),
        );
      }
    } catch (e) {
      print("Đăng nhập Google thất bại: $e");
      setState(() {
        _errorMessage = 'Đăng nhập Google thất bại. Vui lòng thử lại!';
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      // Đảm bảo đẩy nội dung lên khi có bàn phím
      body: SafeArea(
        child: SingleChildScrollView(
          reverse: true, // Đẩy nội dung lên trên cùng khi bàn phím hiện
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery
                .of(context)
                .viewInsets
                .bottom),
            child: IntrinsicHeight(
              // height: MediaQuery.of(context).size.height,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                      color: Colors.blue,
                      alignment: Alignment.center,
                      child: const Text(
                        "LOGIN",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.phone),
                              hintText: "Enter your phone number",
                              border: UnderlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.lock),
                              hintText: "Enter your password",
                              border: UnderlineInputBorder(),
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                                );
                              },
                              child: const Text(
                                "Forgot password?",
                                style: TextStyle(color: Colors.blue),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_errorMessage.isNotEmpty)
                            Text(
                              _errorMessage,
                              style: const TextStyle(color: Colors.red),
                            ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Don’t have an account? "),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context, '/sign_up');
                                },
                                child: const Text(
                                  "Sign Up",
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          ElevatedButton(
                            onPressed:  _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              "Login",
                              style: TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),

                          const SizedBox(height: 20),
                          const Row(
                            children: [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text("or you can"),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(
                                    Icons.facebook, color: Colors.blue),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Icon(
                                    Icons.g_mobiledata, color: Colors.red),
                                onPressed: _signInWithGoogle,
                                // onPressed: (){}
                              ),
                            ],
                          ),
                        ],
                      ),
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