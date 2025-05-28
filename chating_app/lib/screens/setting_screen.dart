import 'package:chating_app/data/user.dart';
import 'package:chating_app/screens/chang_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:chating_app/providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {

  final ObjectUser user;

  const SettingsScreen({super.key, required this.user});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Xóa hết thông tin đã lưu

    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }


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
              currentValue: context.locale.languageCode == 'vi' ? "Vietnamese" : "English",
              items: ["Vietnamese", "English"],
              onChanged: (value) {
                if (value == "Vietnamese") {
                  context.setLocale(const Locale('vi'));
                } else {
                  context.setLocale(const Locale('en'));
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
                  _setThemeMode(context, ThemeMode.dark);
                } else {
                  _setThemeMode(context, ThemeMode.light);
                }
              },
            ),

            const SizedBox(height: 40),

            // Change Password
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangePasswordScreen(
                      phone: user.soDienThoai,
                    ),
                  ),
                );
              },
              child: const Text(
                "Change Password",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 20),

            GestureDetector(
              onTap: () => _logout(context),
              child: const Row(
                children: [
                  Icon(Icons.logout, color: Colors.red),
                  SizedBox(width: 10),
                  Text(
                    "Logout",
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ],
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
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.setThemeMode(themeMode);
  }
}
