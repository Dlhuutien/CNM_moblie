import 'package:chating_app/data/user.dart';
import 'package:chating_app/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:chating_app/data/information.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chating_app/screens/forgot_pass_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:chating_app/services/env_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  String _errorMessage = '';

  void _handleLogin() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    final phoneValid = RegExp(r'^\d{10}$').hasMatch(phone);
    final passwordValid = RegExp(r'^[\S]{8,16}$').hasMatch(password);

    if (!phoneValid) {
      setState(() {
        _errorMessage = 'Phone number must be exactly 10 digits'.tr();
      });
      return;
    }

    if (!passwordValid) {
      setState(() {
        _errorMessage = 'Password 8-16 characters, no spaces.'.tr();
      });
      return;
    }

    ObjectUser? user = await ApiService.login(context, phone, password);

    if (user != null) {
      await _saveUserInfo(user);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen(user: user)),
      );
    } else {
      setState(() {
        _errorMessage = 'Incorrect phone number or password!'.tr();
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      // 1. Đăng nhập bằng Google
      final googleSignIn = GoogleSignIn(
        clientId: "19142047184-ul1hhcea8drflmk5jqokj5cu2aih2be9.apps.googleusercontent.com",
      );
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();


      if (googleUser == null) return;

      // 2. Lấy token từ Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Xác thực với Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      // 4. Kiểm tra email từ Firebase user
      final email = user?.email;
      if (email == null || email.isEmpty) {
        setState(() {
          _errorMessage = 'Google account without email!'.tr();
        });
        return;
      }

      // 5. Gọi API để kiểm tra user trong hệ thống
      final checkResponse = await http.get(
        Uri.parse("${EnvConfig.baseUrl}/user/account?email=$email"),
      );

      print("Response body: ${checkResponse.body}");

      if (checkResponse.statusCode == 200) {
        final dataList = jsonDecode(checkResponse.body);
        if (dataList is List && dataList.isNotEmpty) {
          final data = dataList[0];

          ObjectUser existedUser = ObjectUser(
            userID: data['id'].toString(),
            soDienThoai: data['phone'] ?? '',
            password: data['password'] ?? '',
            hoTen: data['name'] ?? '',
            gender: data['gender'] ?? 'Nam',
            birthday: data['birthday'] ?? '',
            email: data['email'] ?? '',
            work: data['work'] ?? '',
            image: data['image'] ?? '',
            location: data['location'] ?? '',
          );

          await _saveUserInfo(existedUser);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainScreen(user: existedUser)),
          );
        } else {
          // Không có user sẽ tạo mới
          final signupResponse = await http.post(
            Uri.parse("${EnvConfig.baseUrl}/user/signup"),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': user?.displayName ?? '',
              'phone': '',
              'password': email, // Để pass mặc định trùng với email
              'email': email,
            }),
          );

          print("Signup response: ${signupResponse.body}");

          if (signupResponse.statusCode == 200) {
            final data = jsonDecode(signupResponse.body);

            ObjectUser newUser = ObjectUser(
              userID: data['id'].toString(),
              soDienThoai: '',
              password: '',
              hoTen: user?.displayName ?? '',
              gender: 'Nam',
              birthday: '',
              email: email,
              work: '',
              image: user?.photoURL ?? '',
              location: '',
            );

            await _saveUserInfo(newUser);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MainScreen(user: newUser)),
            );
          } else {
            setState(() {
              _errorMessage = 'Cannot create new account!'.tr();
            });
          }
        }
      } else {
        setState(() {
          _errorMessage = 'Lỗi khi kiểm tra tài khoản!';
        });
      }
    } catch (e) {
      print("Google login failed: $e");
      setState(() {
        _errorMessage = 'Google Sign In Failed. Please Try Again!'.tr();
      });
    }
  }

  ///Hàm Lưu thông tin khi đã đăng nhập
  Future<void> _saveUserInfo(ObjectUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userID', user.userID);
    await prefs.setString('userName', user.hoTen);
    await prefs.setString('userEmail', user.email);
    await prefs.setString('userPhone', user.soDienThoai);
    await prefs.setString('userPassword', user.password);
    await prefs.setString('userGender', user.gender);
    await prefs.setString('userBirthday', user.birthday);
    await prefs.setString('userWork', user.work);
    await prefs.setString('userImage', user.image);
    await prefs.setString('userLocation', user.location);
  }

  ///Hàm load thông tin khi đã đăng nhập
  Future<ObjectUser?> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userID = prefs.getString('userID');
    if (userID == null) return null;

    return ObjectUser(
      userID: userID,
      hoTen: prefs.getString('userName') ?? '',
      email: prefs.getString('userEmail') ?? '',
      soDienThoai: prefs.getString('userPhone') ?? '',
      password: prefs.getString('userPassword') ?? '',
      gender: prefs.getString('userGender') ?? 'Nam',
      birthday: prefs.getString('userBirthday') ?? '',
      work: prefs.getString('userWork') ?? '',
      image: prefs.getString('userImage') ?? '',
      location: prefs.getString('userLocation') ?? '',
    );
  }

  @override
  void initState() {
    super.initState();
    _checkLoggedIn();
  }

  void _checkLoggedIn() async {
    ObjectUser? user = await _loadUserInfo();
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen(user: user)),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      // Đẩy nội dung lên khi có bàn phím
      body: SafeArea(
        child: SingleChildScrollView(
          reverse: true, // Đẩy nội dung lên trên cùng khi bàn phím hiện
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery
                .of(context)
                .viewInsets
                .bottom),
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
                        "LOGIN",
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _phoneController,
                            decoration:  InputDecoration(
                              prefixIcon: Icon(Icons.phone),
                              hintText: "Enter your phone number".tr(),
                              border: UnderlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.lock),
                              hintText: "Enter your password".tr(),
                              border: UnderlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
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
                              ).tr(),
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
                              const Text("Don’t have an account?").tr(),
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
                                ).tr(),
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
                            ).tr(),
                          ),

                          const SizedBox(height: 20),
                           Row(
                            children: [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text("or you can".tr()),
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