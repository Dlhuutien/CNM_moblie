import 'package:flutter/material.dart';

class ChatProfileScreen extends StatelessWidget {
  final String name;

  const ChatProfileScreen({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Setting"),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              // Thêm chức năng gọi
            },
          ),
          IconButton(
            icon: const Icon(Icons.push_pin),
            onPressed: () {
              // Thêm chức năng gọi video
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Thêm chức năng menu khác
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage("http://"),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text("Designer", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),

            // Thông tin chi tiết
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text("(090)0000"),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text("12/12/2022"),
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text("India"),
            ),
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text("Create group"),
            ),
            const ListTile(
              leading: Icon(Icons.block, color: Colors.red),
              title: Text("Block", style: TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 20),

            // Images Section
            const Text(
              "Image 52",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 9, // Số lượng ảnh
              itemBuilder: (context, index) {
                return Image.network(
                  "https://", // Thay bằng link ảnh
                  fit: BoxFit.cover,
                );
              },
            ),
            const SizedBox(height: 20),

            // Link và File Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("Link 2", style: TextStyle(fontSize: 16)),
                Icon(Icons.add),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("File 2", style: TextStyle(fontSize: 16)),
                Icon(Icons.add),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
