import 'package:flutter/material.dart';
import 'package:chating_app/data/user.dart';

class ProfileScreen extends StatelessWidget {
  final User user;
  const ProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0, // Ẩn AppBar mặc định
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header section: Avatar and name
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
                borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage('assets/profile.png'),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: const CircleAvatar(
                          radius: 15,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.edit,
                              size: 18, color: Colors.blueAccent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user.hoTen,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Info section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ProfileInfo(user: user),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileInfo extends StatelessWidget {
  final User user;
  const ProfileInfo({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Phone:', user.soDienThoai),
        _buildInfoRow('Gender:', user.gender),
        _buildInfoRow('Birthday:', user.birthday),
        _buildInfoRow('Email:', user.email),
        _buildInfoRow('Work:', user.work),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Text(value),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Colors.blueAccent),
                onPressed: () {
                  // Chức năng chỉnh sửa sẽ thêm sau nếu cần
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
