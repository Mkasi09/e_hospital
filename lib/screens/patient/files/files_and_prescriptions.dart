import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
// import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class FilesAndPrescriptionsScreen extends StatefulWidget {
  const FilesAndPrescriptionsScreen({super.key});

  @override


  State<FilesAndPrescriptionsScreen> createState() =>
      _FilesAndPrescriptionsScreenState();
}

class _FilesAndPrescriptionsScreenState
    extends State<FilesAndPrescriptionsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  // Firestore collection references (adjust 'patients' and 'patientId' as needed)
  final String patientId = "patient_123"; // Replace with actual logged in patient ID
  final CollectionReference patientFilesCollection = FirebaseFirestore.instance
      .collection('patients')
      .doc("patient_123")
      .collection('uploaded_files');

  final List<Map<String, String>> _hospitalFiles = [
    {'title': 'Blood Test Report', 'date': '2025-03-10'},
    {'title': 'X-Ray Results', 'date': '2025-04-01'},
    {'title': 'Prescription - Dr. Smith', 'date': '2025-05-15'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /* Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.single.path!;
      final fileName = result.files.single.name;

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('patients')
          .child(patientId)
          .child('uploads')
          .child(fileName);

      final uploadTask = storageRef.putFile(File(filePath));

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Save metadata to Firestore
      await patientFilesCollection.add({
        'title': fileName,
        'date': DateTime.now(),
        'status': 'pending', // new uploads start as pending
        'downloadUrl': downloadUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document uploaded for review.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }*/

  Future<void> _deletePatientFile(String docId) async {
    try {
      await patientFilesCollection.doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document deleted.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Widget _buildVerifiedFileCard({required String title, required String date}) {
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Viewing official file: "$title"')),
          );
        },
      ),
    );
  }

  Widget _buildPatientFileCard({
    required String docId,
    required String title,
    required DateTime date,
    required String status,
    required String downloadUrl,
  }) {
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_bottom;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Icon(Icons.upload_file, color: Colors.orange),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Date: ${date.toLocal().toIso8601String().split('T').first}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon, color: statusColor, size: 20),
            const SizedBox(width: 8),
            Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
            if (status == 'pending') ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.grey),
                tooltip: 'Delete',
                onPressed: () => _deletePatientFile(docId),
              ),
            ],
          ],
        ),
        onTap: () {
          // Open file URL (for now just showing snackbar)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening document: "$title"')),
          );
          // To actually open/download, integrate url_launcher or a PDF/image viewer
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Files & Prescriptions'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: null,
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload Document'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Official Hospital Files',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._hospitalFiles.map((file) =>
                _buildVerifiedFileCard(title: file['title']!, date: file['date']!)),
            const Divider(height: 32),

            const Text(
              'My Uploaded Documents',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // StreamBuilder to listen to Firestore patient files collection
            StreamBuilder<QuerySnapshot>(
              stream: patientFilesCollection.orderBy('date', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Error loading documents.');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Text(
                    'You have not uploaded any documents yet.',
                    style: TextStyle(color: Colors.grey),
                  );
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data()! as Map<String, dynamic>;
                    return _buildPatientFileCard(
                      docId: doc.id,
                      title: data['title'] ?? 'Untitled',
                      date: (data['date'] as Timestamp).toDate(),
                      status: data['status'] ?? 'pending',
                      downloadUrl: data['downloadUrl'] ?? '',
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 80), // Bottom padding so FAB doesn't overlap
          ],
        ),
      ),
    );
  }
}
