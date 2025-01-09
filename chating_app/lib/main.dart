import 'package:flutter/material.dart';
import 'screens/introduction_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/signUp_screen.dart'; // Import màn hình SignUp

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/sign_up', // Bắt đầu từ màn hình SignUp
      routes: {
        '/': (context) => IntroductionScreen(),
        '/login': (context) => LoginScreen(),
        '/main': (context) => MainScreen(),
        '/sign_up': (context) => SignUpScreen(), // Thêm màn hình SignUp
      },
    );
  }
}