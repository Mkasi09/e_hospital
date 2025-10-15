import 'package:e_hospital/screens/doctor/patients/doctors_patient_history_screen.dart';
import 'package:e_hospital/screens/patient/files/upload_confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'official_hospital_file_cards.dart';
import 'patient_file_card.dart';
import 'file_upload_service.dart';

class FilesAndPrescriptionsScreen extends StatefulWidget {
  const FilesAndPrescriptionsScreen({super.key});

  @override
  State<FilesAndPrescriptionsScreen> createState() =>
      _FilesAndPrescriptionsScreenState();
}

class _FilesAndPrescriptionsScreenState
    extends State<FilesAndPrescriptionsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  File? _selectedFile;
  String? _selectedFileName;
  String? _selectedFileExtension;
  bool _isUploading = false;

  final String patientId = FirebaseAuth.instance.currentUser!.uid;
  final CollectionReference patientFilesCollection = FirebaseFirestore.instance
      .collection('uploaded_files');

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

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result == null || result.files.isEmpty) return;

    setState(() {
      _selectedFile = File(result.files.single.path!);
      _selectedFileName = result.files.single.name;
      _selectedFileExtension = result.files.single.extension?.toLowerCase();
    });

    showFilePreviewDialog(
      context: context,
      file: _selectedFile!,
      fileName: _selectedFileName!,
      extension: _selectedFileExtension!,
      isUploading: _isUploading,
      onUpload: () async {
        setState(() => _isUploading = true);
        await uploadFileToCloudinaryAndFirestore(
          file: _selectedFile!,
          fileName: _selectedFileName!,
          patientFilesCollection: patientFilesCollection,
          context: context,
        );
        setState(() => _isUploading = false);
      },
      onCancel: () {
        setState(() {
          _selectedFile = null;
          _selectedFileName = null;
          _selectedFileExtension = null;
        });
      },
    );
  }

  Future<void> _deletePatientFile(String docId) async {
    try {
      await patientFilesCollection.doc(docId).delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Document deleted.')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Files & Prescriptions'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickFile,
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

            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('doctor_uploaded_files')
                      .where('userId', isEqualTo: patientId)
                      .orderBy('date', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Error loading hospital files.');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.docs.isEmpty) {
                  return Column(
                    children: const [
                      Icon(
                        Icons.insert_drive_file,
                        size: 60,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No official files available.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  );
                }

                return Column(
                  children:
                      snapshot.data!.docs.map((doc) {
                        final data = doc.data()! as Map<String, dynamic>;
                        return buildVerifiedFileCard(
                          title: data['title'] ?? 'Untitled',
                          date:
                              (data['date'] as Timestamp?)
                                  ?.toDate()
                                  .toString()
                                  .split(' ')[0] ??
                              '',
                        );
                      }).toList(),
                );
              },
            ),
            const Divider(height: 32),
            const Text(
              'My Uploaded Documents',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream:
                  patientFilesCollection
                      .orderBy('date', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return const Text('Error loading documents.');
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                if (snapshot.data!.docs.isEmpty) {
                  return Column(
                    children: const [
                      Icon(Icons.folder_off, size: 60, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'You have not uploaded any documents yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  );
                }
                return Column(
                  children:
                      snapshot.data!.docs.map((doc) {
                        final data = doc.data()! as Map<String, dynamic>;
                        return PatientFileCard(
                          docId: doc.id,
                          title: data['title'] ?? 'Untitled',
                          date: (data['date'] as Timestamp).toDate(),
                          status: data['status'] ?? 'pending',
                          downloadUrl: data['downloadUrl'] ?? '',
                          onDelete: () => _deletePatientFile(doc.id),
                          content: null,
                        );
                      }).toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Prescriptions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('prescriptions')
                      .where('userId', isEqualTo: patientId)
                      .orderBy('date', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return const Text('Error loading prescriptions.');
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.docs.isEmpty) {
                  return Column(
                    children: const [
                      Icon(
                        Icons.medical_services,
                        size: 60,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No prescriptions available.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  );
                }

                return Column(
                  children:
                      snapshot.data!.docs.map((doc) {
                        final data = doc.data()! as Map<String, dynamic>;
                        return PatientFileCard(
                          docId: doc.id,
                          title: data['title'] ?? 'Prescription',
                          date: (data['date'] as Timestamp).toDate(),
                          status: data['status'] ?? 'reviewed',
                          downloadUrl: null,
                          content: data['content'] ?? '',
                          onDelete: () async {
                            await FirebaseFirestore.instance
                                .collection('prescriptions')
                                .doc(doc.id)
                                .delete();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Prescription deleted'),
                              ),
                            );
                          },
                        );
                      }).toList(),
                );
              },
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
