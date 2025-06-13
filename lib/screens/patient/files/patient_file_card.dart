import 'package:flutter/material.dart';
import 'file_viewer_screen.dart';

class PatientFileCard extends StatelessWidget {
  final String docId;
  final String title;
  final DateTime date;
  final String status;
  final String downloadUrl;
  final VoidCallback onDelete;

  const PatientFileCard({
    super.key,
    required this.docId,
    required this.title,
    required this.date,
    required this.status,
    required this.downloadUrl,
    required this.onDelete,
  });

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(), // Cancel
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Close dialog
              onDelete(); // Call delete callback
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final extension = downloadUrl.split('.').last.toLowerCase();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(
          extension == 'pdf' ? Icons.picture_as_pdf : Icons.image,
          color: extension == 'pdf' ? Colors.red : Colors.blue,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Uploaded on: ${date.toLocal().toString().split(' ')[0]}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _showDeleteConfirmation(context),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FileViewerScreen(
                fileUrl: downloadUrl,
                fileName: title,
                fileExtension: extension,
              ),
            ),
          );
        },
      ),
    );
  }
}
