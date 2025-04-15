import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:chating_app/data/user.dart';
import 'package:http_parser/http_parser.dart'; // dùng cho MediaType



class ProfileScreen extends StatefulWidget {
  final ObjectUser user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ObjectUser _editableUser;

  @override
  void initState() {
    super.initState();
    _editableUser = widget.user;
  }

  Future<void> updateUserField(String field, String newValue) async {
    final updatedUser = _editableUser.copyWithField(field, newValue);

    final url = Uri.parse("http://138.2.106.32/user/update");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "id": int.parse(updatedUser.userID),
        "name": updatedUser.hoTen,
        "password": updatedUser.matKhau,
        "phone": updatedUser.soDienThoai,
        "image": updatedUser.image,
        "location": updatedUser.location,
        "birthday": updatedUser.birthday,
        "email": updatedUser.email,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        _editableUser = updatedUser;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cập nhật thất bại: ${response.body}")),
      );
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final url = Uri.parse("http://138.2.106.32/user/upload");

      final fileBytes = await pickedFile.readAsBytes(); // Đọc file thành byte array
      final fileName = pickedFile.name;

      var request = http.MultipartRequest("POST", url);
      request.files.add(http.MultipartFile.fromBytes(
        "file", // phải là "file" đúng như backend
        fileBytes,
        filename: fileName,
        contentType: MediaType("image", "jpeg"),
      ));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody);

        if (data['ok'] == 1) {
          final imageUrl = data['imageUrl'];
          await updateUserField('image', imageUrl);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Upload ảnh thất bại: ${data['message']}")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload ảnh thất bại (status): ${response.statusCode}")),
        );
      }
    }
  }

  String _formatDateOnly(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (_) {
      return isoDate;
    }
  }

  Future<void> _editField(String fieldName, String label, String currentValue) async {
    if (fieldName == 'birthday') {
      DateTime initialDate;
      try {
        initialDate = DateTime.parse(currentValue);
      } catch (_) {
        initialDate = DateTime.now();
      }

      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(1900),
        lastDate: DateTime.now(), // Không cho chọn ngày tương lai
      );

      if (pickedDate != null) {
        final formattedDate = pickedDate.toIso8601String();
        await updateUserField(fieldName, formattedDate);
      }
    } else {
      final controller = TextEditingController(text: currentValue);
      String? newValue = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Chỉnh sửa $label"),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: "Nhập $label mới"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Huỷ")),
            TextButton(onPressed: () => Navigator.pop(context, controller.text), child: Text("Lưu")),
          ],
        ),
      );

      if (newValue != null && newValue.trim().isNotEmpty && newValue != currentValue) {
        if (fieldName == 'email' && !RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(newValue)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Email không hợp lệ")),
          );
          return;
        }

        if (fieldName == 'phone' && !RegExp(r'^\d10$').hasMatch(newValue)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Số điện thoại không hợp lệ")),
          );
          return;
        }

        if (fieldName == 'name' &&
            !RegExp(r"^([A-ZÀ-Ỵ][a-zà-ỵ]+)( [A-ZÀ-Ỵ][a-zà-ỵ]+)*$", unicode: true)
                .hasMatch(newValue.trim())) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Tên phải viết hoa chữ cái đầu và không chứa ký tự đặc biệt")),
          );
          return;
        }

        await updateUserField(fieldName, newValue);
      }

    }
  }

  Widget _buildInfoRow(String label, String fieldKey, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: Colors.blueAccent),
                  onPressed: () => _editField(fieldKey, label, value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(_editableUser.image),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _pickAndUploadImage,
                          child: const CircleAvatar(
                            radius: 15,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.edit, size: 18, color: Colors.blueAccent),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _editableUser.hoTen,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Name:', 'name', _editableUser.hoTen),
                  _buildInfoRow('Phone:', 'phone', _editableUser.soDienThoai),
                  _buildInfoRow('Gender:', 'gender', _editableUser.gender),
                  _buildInfoRow('Birthday:', 'birthday', _formatDateOnly(_editableUser.birthday)),
                  _buildInfoRow('Email:', 'email', _editableUser.email),
                  _buildInfoRow('Work:', 'work', _editableUser.work),
                  _buildInfoRow('Location:', 'location', _editableUser.location),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
