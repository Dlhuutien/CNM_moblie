import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Thực hiện hành động khi thêm gì đó (ví dụ: tạo mới)
            },
          ),
        ],
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header section: Avatar and name
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: const BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
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
                        child: Icon(Icons.edit, size: 18, color: Colors.blueAccent),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'LY QUOC MINH',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Info section
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: ProfileInfo(),
          ),
        ],
      ),
    );
  }
}

class ProfileInfo extends StatelessWidget {
  const ProfileInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Phone:', '(090)000000', context),
        _buildInfoRow('Gender:', 'Male', context),
        _buildInfoRow('Birthday:', '06/12/2003', context),
        _buildInfoRow('Email:', 'lyquocminh@gmail.com', context),
        _buildInfoRow('Work:', 'Frontend Engineer', context),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, BuildContext context) {
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
                  // Thực hiện hành động khi chỉnh sửa thông tin
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
