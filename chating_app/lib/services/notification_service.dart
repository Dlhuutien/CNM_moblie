import 'package:flutter/material.dart';
import 'package:chating_app/widgets/notification_banner.dart';

class NotificationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
}
