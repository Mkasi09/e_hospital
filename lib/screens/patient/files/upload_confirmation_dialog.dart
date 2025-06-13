import 'dart:io';
import 'package:flutter/material.dart';

void showFilePreviewDialog({
  required BuildContext context,
  required File file,
  required String fileName,
  required String extension,
  required bool isUploading,
  required VoidCallback onCancel,
  required Future<void> Function() onUpload,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Confirm Upload'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                getFileIcon(extension),
                const SizedBox(height: 16),
                Text(fileName),
                const SizedBox(height: 16),
                if (isUploading) const Text('Uploading...'),
              ],
            ),
            actions: [
              if (!isUploading)
                TextButton(onPressed: () {
                  Navigator.of(context).pop();
                  onCancel();
                }, child: const Text('Cancel')),
              if (!isUploading)
                ElevatedButton(
                  onPressed: () async {
                    setState(() => isUploading = true);
                    await onUpload();
                    setState(() => isUploading = false);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Upload'),
                ),
            ],
          );
        },
      );
    },
  );
}

Widget getFileIcon(String extension) {
  switch (extension) {
    case 'pdf':
      return const Icon(Icons.picture_as_pdf, size: 64, color: Colors.red);
    case 'jpg':
    case 'jpeg':
    case 'png':
      return const Icon(Icons.image, size: 64, color: Colors.blue);
    default:
      return const Icon(Icons.insert_drive_file, size: 64, color: Colors.grey);
  }
}
