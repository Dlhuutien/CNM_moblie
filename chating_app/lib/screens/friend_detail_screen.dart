import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';


class FriendDetailScreen extends StatelessWidget {
  final Map<String, dynamic> friend;
  const FriendDetailScreen({super.key, required this.friend});

  String _formatDateOnly(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (_) {
      return isoDate;
    }
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = friend['image'] ?? '';
    final name = friend['name'] ?? 'No Name';
    final phone = friend['phone'] ?? 'No Phone';
    final email = friend['email'] ?? 'No Email';
    final location = friend['location'] ?? 'No Location';
    final birthday = friend['birthday'] ?? 'No Birthday';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Friend Profile",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
                    backgroundColor: Colors.blue.shade700,
                    child: image.isEmpty ? const Icon(Icons.person, size: 50, color: Colors.white) : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    name,
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
                  _buildInfoRow(context,'Name'.tr(), name),
                  _buildInfoRow(context,'Phone'.tr(), phone),
                  _buildInfoRow(context,'Email'.tr(), email),
                  _buildInfoRow(context,'Location'.tr(), location),
                  _buildInfoRow(context, 'Birthday'.tr(), _formatDateOnly(birthday.toString())),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
