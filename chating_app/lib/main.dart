import 'package:chating_app/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'screens/introduction_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signUp_screen.dart';
import 'package:chating_app/services/env_config.dart';
import 'package:provider/provider.dart';
import 'package:chating_app/providers/theme_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Future<void> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (status.isGranted) {
      print("Notification permission granted");
    } else {
      print("Notification permission denied");
    }
  }

  // Load .env file trước khi dùng EnvConfig
  // await dotenv.load(fileName: ".env");
  // await EnvConfig.init();
  // print("BASE_URL hiện tại: ${EnvConfig.baseUrl}");

  try {
    await EnvConfig.init();
  } catch (e) {
    print("Lỗi khi load env: $e");
  }
  await EasyLocalization.ensureInitialized();
  await requestNotificationPermission();

  // WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: kIsWeb
        ? FirebaseOptions(
      apiKey: "AIzaSyDh0gojs-o77JQmk8W35U8kxGXpGjDpM10",
      authDomain: "chatingapp-8543b.firebaseapp.com",
      projectId: "chatingapp-8543b",
      storageBucket: "chatingapp-8543b.appspot.com",
      messagingSenderId: "19142047184",
      appId: "1:19142047184:web:7735549a5e41e9838675d5",
    )
        : null,
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('vi')],
      path: 'assets/translations', // Thư mục chứa file JSON
      fallbackLocale: const Locale('en'),
      child: ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: MyApp(),
      ),
      // child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      /**
       * Hiển thị thông báo trên top
       */
      navigatorKey: NotificationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const IntroductionScreen(),
        '/login': (context) => const LoginScreen(),
        '/sign_up': (context) => SignUpScreen(),
      },
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      themeMode: themeProvider.themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
    );
  }
}
