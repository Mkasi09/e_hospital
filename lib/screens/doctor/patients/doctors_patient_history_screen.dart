import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

import '../../patient/files/patient_file_card.dart';



class UserDetailsScreen extends StatefulWidget {
  final String userId;

  const UserDetailsScreen({super.key, required this.userId});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  late String address;

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : "Not provided",
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
  Future<void> _uploadFileToPatient(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles();

    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.first.path;
    final fileName = result.files.first.name;

    if (filePath == null) return;

    final file = File(filePath);
    final cloudinaryUploadUrl = Uri.parse('https://api.cloudinary.com/v1_1/dzz3iovq5/raw/upload');

    final request = http.MultipartRequest('POST', cloudinaryUploadUrl)
      ..fields['upload_preset'] = 'ehospital'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    try {
      final response = await request.send();
      final responseData = await http.Response.fromStream(response);
      final data = json.decode(responseData.body);

      if (response.statusCode == 200) {
        final downloadUrl = data['secure_url'];

        await FirebaseFirestore.instance.collection('doctor_uploaded_files').add({
          'userId': widget.userId,
          'title': fileName,
          'downloadUrl': downloadUrl,
          'status': 'reviewed',
          'uploadedBy': 'doctor',
          'date': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully to Cloudinary.')),
        );
      } else {
        throw Exception('Upload failed: ${data['error']['message']}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Details')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _uploadFileToPatient(context),
          backgroundColor: Colors.blueAccent,
          icon: const Icon(Icons.upload_file),
          label: const Text('Upload Documents'),
        ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading user data.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;

          if (data == null) {
            return const Center(child: Text('User not found.'));
          }

          address = data['address'] ?? 'N/A';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // User Details Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personal Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _infoRow('Full Name', data['fullName'] ?? 'N/A'),
                      _infoRow('ID Number', data['id'] ?? 'N/A'),
                      _infoRow('Gender', data['gender'] ?? 'N/A'),
                      _infoRow('Date of Birthday', data['dob'] ?? 'N/A'),
                      _infoRow('Phone Number', data['phone'] ?? 'N/A'),
                      _infoRow(
                        'Next of Kin',
                        '${data['nextOfKin'] ?? 'N/A'} (${data['nextOfKinPhone'] ?? ''})',
                      ),
                      _infoRow('Address', address),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  'Patient Uploaded Files',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('uploaded_files')
                        .where('userId', isEqualTo: widget.userId)
                        //.orderBy('date', descending: true)
                        .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text('Error loading uploaded files.');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    final files = snapshot.data?.docs ?? [];

                    if (files.isEmpty) {
                      return const Text('No files uploaded yet.');
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: files.length,
                      itemBuilder: (context, index) {
                        final doc = files[index];
                        final data = doc.data() as Map<String, dynamic>;

                        final title = data['title'] ?? 'Unnamed file';
                        final url = data['downloadUrl'] ?? '';
                        final status = data['status'] ?? 'N/A';
                        final timestamp = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();

                        return PatientFileCard(
                          docId: doc.id,
                          title: title,
                          date: timestamp,
                          status: status,
                          downloadUrl: url,
                          onDelete: () async {
                            await FirebaseFirestore.instance
                                .collection('uploaded_files')
                                .doc(doc.id)
                                .delete();

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('File deleted')),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                // Section: Hospital Uploaded Files
                const SizedBox(height: 32),
                const Text(
                  'Hospital Uploaded Files',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('doctor_uploaded_files')
                      .where('userId', isEqualTo: widget.userId)
                      //.orderBy('date', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text('Error loading hospital files.');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    final files = snapshot.data?.docs ?? [];

                    if (files.isEmpty) {
                      return const Text('No files uploaded by hospital yet.');
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: files.length,
                      itemBuilder: (context, index) {
                        final doc = files[index];
                        final data = doc.data() as Map<String, dynamic>;

                        final title = data['title'] ?? 'Unnamed file';
                        final url = data['downloadUrl'] ?? '';
                        final status = data['status'] ?? 'N/A';
                        final timestamp = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();

                        return PatientFileCard(
                          docId: doc.id,
                          title: title,
                          date: timestamp,
                          status: status,
                          downloadUrl: url,
                          onDelete: () async {
                            await FirebaseFirestore.instance
                                .collection('doctor_uploaded_files')
                                .doc(doc.id)
                                .delete();

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('File deleted')),
                            );
                          },
                        );
                      },
                    );
                  },
                ),



              ],
            ),
          );
        },
      ),

    );
  }
}
