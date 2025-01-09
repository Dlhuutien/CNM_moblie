import 'package:flutter/material.dart';

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
              title: "Language",
              currentValue: "Tieng Viet",
              items: ["Tieng Viet", "English"],
            ),

            const SizedBox(height: 20),

            // Mode Setting
            _buildDropdownSetting(
              title: "Mode",
              currentValue: "Dark mode",
              items: ["Light mode", "Dark mode"],
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
          onChanged: (value) {
            // Thêm logic xử lý khi chọn giá trị khác
          },
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
}
