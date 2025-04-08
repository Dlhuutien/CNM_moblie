import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'screens/introduction_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/signUp_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('vi')],
      path: 'assets/translations', // Thư mục chứa file JSON
      fallbackLocale: const Locale('en'),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const IntroductionScreen(),
        '/login': (context) => const LoginScreen(),
        // '/main': (context) => const MainScreen(),
        '/sign_up': (context) => SignUpScreen(),
      },
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}
