import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../doctor/patients/prescription_details_popup.dart';
import 'file_viewer_screen.dart';

class PatientFileCard extends StatelessWidget {
  final String docId;
  final String title;
  final DateTime date;
  final String status;
  final String? downloadUrl;
  final String? content;
  final VoidCallback onDelete;

  /// NEW: callback to show text prescription
  final VoidCallback? onOpenTextPrescription;

  const PatientFileCard({
    super.key,
    required this.docId,
    required this.title,
    required this.date,
    required this.status,
    this.downloadUrl,
    this.content,
    required this.onDelete,
    this.onOpenTextPrescription,
  });

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: Text('Are you sure you want to delete "$title"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onDelete();
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = (downloadUrl != null && downloadUrl!.isNotEmpty);
    final isPdf = hasFile && downloadUrl!.toLowerCase().endsWith('.pdf');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(
          hasFile
              ? (isPdf ? Icons.picture_as_pdf : Icons.insert_drive_file)
              : Icons.description,
          color:
              hasFile
                  ? (isPdf ? Colors.red : Colors.blue)
                  : Colors.grey.shade700,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          'Uploaded on: ${date.toLocal().toString().split(' ')[0]}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _showDeleteConfirmation(context),
        ),
        onTap:
            hasFile
                ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => FileViewerScreen(
                            fileUrl: downloadUrl!,
                            fileName: title,
                            fileExtension:
                                downloadUrl!.split('.').last.toLowerCase(),
                          ),
                    ),
                  );
                }
                : () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => PrescriptionDetailsPopup(docId: docId),
                  );
                },
      ),
    );
  }
}
