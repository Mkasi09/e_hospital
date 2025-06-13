import 'package:flutter/material.dart';

Widget buildVerifiedFileCard({required String title, required String date}) {
  return Card(
    elevation: 2,
    margin: const EdgeInsets.only(bottom: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      leading: const Icon(Icons.verified, color: Colors.blue),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('Date: $date'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        debugPrint('Viewing file: $title');
      },
    ),
  );
}
