import 'package:flutter/material.dart';

/// Widget hiển thị thông báo dạng banner trượt từ trên xuống
class NotificationBanner extends StatefulWidget {
  final String message; // Nội dung thông báo
  final Duration duration; // Thời gian hiển thị banner

  const NotificationBanner({
    super.key,
    required this.message,
    this.duration = const Duration(seconds: 5),
  });

  @override
  State<NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<NotificationBanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller; // Điều khiển animation
  late Animation<Offset> _animation; // Animation cho vị trí trượt

  @override
  void initState() {
    super.initState();

    // Tạo controller để điều khiển animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // Animation xuất hiện 300ms
    );

    // Tạo animation trượt từ trên xuống (từ -1 đến 0.05)
    _animation = Tween<Offset>(
      begin: const Offset(0, -1),     // Trượt từ ngoài màn hình trên
      end: const Offset(0, 0.05),     // Dừng ở vị trí thấp hơn một chút (0.05)
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Bắt đầu animation
    _controller.forward();

    // Sau thời gian hiển thị, banner tự trượt lên lại và biến mất
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // Giải phóng controller khi widget bị huỷ
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 40, // Cách mép trên ... pixel
      left: 20,
      right: 20, // Căn giữa, không full màn
      child: SlideTransition(
        position: _animation, // Áp dụng animation vị trí
        child: Material(
          elevation: 4, // Đổ bóng
          borderRadius: BorderRadius.circular(12), // Bo góc
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white, // Nền trắng
              border: Border.all(color: Colors.blue), // Viền xanh
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text(
              widget.message,
              style: const TextStyle(
                color: Colors.blue, // Chữ xanh
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center, // Căn giữa nội dung
            ),
          ),
        ),
      ),
    );
  }
}
