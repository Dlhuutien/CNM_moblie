import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language Setting
            _buildDropdownSetting(
              title: "Language".tr(),
              currentValue: context.locale.languageCode == 'vi' ? "Tieng Viet" : "English",
              items: ["Tieng Viet", "English"],
              onChanged: (value) {
                if (value == "Tieng Viet") {
                  context.setLocale(Locale('vi'));
                } else {
                  context.setLocale(Locale('en'));
                }
              },
            ),

            const SizedBox(height: 20),

            // Mode Setting
            _buildDropdownSetting(
              title: "Mode".tr(),
              currentValue: Theme.of(context).brightness == Brightness.dark ? "Dark mode" : "Light mode",
              items: ["Light mode", "Dark mode"],
              onChanged: (value) {
                if (value == "Dark mode") {
                  // Chuyển sang chế độ tối
                  _setThemeMode(context, ThemeMode.dark);
                } else {
                  // Chuyển sang chế độ sáng
                  _setThemeMode(context, ThemeMode.light);
                }
              },
            ),

            const SizedBox(height: 40),

            // Change Account
            GestureDetector(
              onTap: () {
                // Thêm logic xử lý khi nhấn vào "Change Account"
              },
              child: const Text(
                "Change Account",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Logout
            GestureDetector(
              onTap: () {
                // Thêm logic xử lý khi nhấn vào "Logout"
              },
              child: const Text(
                "Logout",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget để tạo phần cài đặt có Dropdown
  Widget _buildDropdownSetting({
    required String title,
    required String currentValue,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: currentValue,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          items: items
              .map((item) => DropdownMenuItem(
            value: item,
            child: Text(item),
          ))
              .toList(),
        ),
      ],
    );
  }

  // Hàm để thay đổi chế độ sáng/tối
  void _setThemeMode(BuildContext context, ThemeMode themeMode) {
    // Cập nhật trạng thái chế độ trong ứng dụng
    final themeNotifier = Theme.of(context);
    themeNotifier.brightness == Brightness.dark
        ? themeMode = ThemeMode.dark
        : themeMode = ThemeMode.light;

    // Thêm logic lưu trạng thái vào SharedPreferences hoặc Provider nếu cần thiết
  }
}
