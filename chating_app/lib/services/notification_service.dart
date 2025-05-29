import 'package:flutter/material.dart';
import 'package:chating_app/widgets/notification_banner.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static void showBanner(String message, {Duration duration = const Duration(seconds: 3)}) {
    final overlay = navigatorKey.currentState?.overlay;

    if (overlay == null) {
      print("Overlay not available yet");
      return;
    }

    final entry = OverlayEntry(
      builder: (_) => NotificationBanner(message: message, duration: duration),
    );

    overlay.insert(entry);

    // Tự động remove banner sau duration + animation
    Future.delayed(duration + const Duration(milliseconds: 300), () {
      entry.remove();
    });
  }

  /// Hàm init để gọi trong main
  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings();

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  /// Hiển thị thông báo hệ thống
  static Future<void> showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Thông báo hệ thống',
      channelDescription: 'Thông báo từ local device',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // unique ID
      title,
      body,
      platformDetails,
    );
  }
}
