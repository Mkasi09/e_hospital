import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import '../../patient/files/patient_file_card.dart';

class UserDetailsScreen extends StatefulWidget {
  final String userId;
  const UserDetailsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  late String address;
  final CollectionReference patientFilesCollection =
  FirebaseFirestore.instance.collection('uploaded_files');

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : "Not provided",
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 15,
              ),
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
    final cloudinaryUploadUrl =
    Uri.parse('https://api.cloudinary.com/v1_1/dzz3iovq5/raw/upload');

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

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully.')),
        );
      } else {
        throw Exception('Upload failed: ${data['error']['message']}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  Widget _buildFilesSection(
      String title,
      Stream<QuerySnapshot> stream,
      CollectionReference collectionRef,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 40, thickness: 1),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: patientFilesCollection.orderBy('date', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Text('Error loading documents.');
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.data!.docs.isEmpty) {
              return Column(
                children: const [
                  Icon(Icons.folder_off, size: 60, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('You have not uploaded any documents yet.', style: TextStyle(color: Colors.grey)),
                ],
              );
            }
            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data()! as Map<String, dynamic>;
                return PatientFileCard(
                  docId: doc.id,
                  title: data['title'] ?? 'Untitled',
                  date: (data['date'] as Timestamp).toDate(),
                  status: data['status'] ?? 'pending',
                  downloadUrl: data['downloadUrl'] ?? '', onDelete: () {  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient \'s Details'),
        backgroundColor: Colors.blueAccent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _uploadFileToPatient(context),
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload Documents'),
        tooltip: 'Upload a document for this patient',
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
        FirebaseFirestore.instance.collection('users').doc(widget.userId).get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading user data.',
                style: TextStyle(color: theme.colorScheme.error, fontSize: 16),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data?.data() as Map<String, dynamic>?;

          if (data == null) {
            return Center(
              child: Text(
                'User not found.',
                style: TextStyle(color: theme.colorScheme.error, fontSize: 16),
              ),
            );
          }

          final addressMap = data['address'] as Map<String, dynamic>? ?? {};

          final fullAddress = [
            addressMap['street'],
            addressMap['city'],
            addressMap['province'],
            addressMap['postalCode'],
            addressMap['country'],
          ].where((e) => e != null && e.toString().isNotEmpty).join(', ');


          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Personal Details Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personal Details',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _infoRow('Full Name', data['fullName'] ?? 'N/A'),
                        _infoRow('ID Number', data['id'] ?? 'N/A'),
                        _infoRow('Gender', data['gender'] ?? 'N/A'),
                        _infoRow('Date of Birth', data['dob'] ?? 'N/A'),
                        _infoRow('Phone Number', data['phone'] ?? 'N/A'),
                        _infoRow(
                          'Next of Kin',
                          '${data['nextOfKin'] ?? 'N/A'} (${data['nextOfKinPhone'] ?? ''})',
                        ),
                        _infoRow('Address', fullAddress.isNotEmpty ? fullAddress : 'Not provided'),

                      ],
                    ),
                  ),
                ),

                // Medical Information Card
                Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(top: 32),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Medical Information',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _infoRow('Blood Group', data['bloodGroup'] ?? 'Not Provided'),
                        _infoRow('Allergies', data['allergies'] ?? 'Not Provided'),
                        _infoRow('Chronic Conditions',
                            data['chronicConditions'] ?? 'Not Provided'),
                        _infoRow('Medications', data['medications'] ?? 'Not Provided'),
                        _infoRow('Primary Doctor', data['primaryDoctor'] ?? 'Not Provided'),
                      ],
                    ),
                  ),
                ),

                // Uploaded Files Sections
                _buildFilesSection(
                  'Patient Uploaded Files',
                  FirebaseFirestore.instance
                      .collection('uploaded_files')
                      .where('userId', isEqualTo: widget.userId)
                      .snapshots(),
                  FirebaseFirestore.instance.collection('uploaded_files')
                ),

                _buildFilesSection(
                  'Hospital Uploaded Files',
                  FirebaseFirestore.instance
                      .collection('doctor_uploaded_files')
                      .where('userId', isEqualTo: widget.userId)
                      .snapshots(),
                  FirebaseFirestore.instance.collection('doctor_uploaded_files'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
