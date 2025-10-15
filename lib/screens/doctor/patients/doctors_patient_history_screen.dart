import 'package:e_hospital/screens/doctor/patients/prescription.dart';
import 'package:e_hospital/screens/doctor/patients/prescription_details_popup.dart';
import 'package:e_hospital/screens/doctor/patients/request_service_popup.dart';
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
  final CollectionReference patientFilesCollection = FirebaseFirestore.instance
      .collection('uploaded_files');

  /// ============= SERVICE REQUEST ==============
  Future<void> _requestService() async {
    await ServiceRequestPopup.show(context: context, userId: widget.userId);
  }

  /// ============= CLOUDINARY UPLOAD ==============
  Future<String?> _uploadToCloudinary(File file) async {
    final uploadUrl = Uri.parse(
      'https://api.cloudinary.com/v1_1/dzz3iovq5/raw/upload',
    );
    final request =
        http.MultipartRequest('POST', uploadUrl)
          ..fields['upload_preset'] = 'ehospital'
          ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final responseData = await http.Response.fromStream(response);
    final data = json.decode(responseData.body);

    if (response.statusCode == 200) {
      return data['secure_url'];
    } else {
      throw Exception('Upload failed: ${data['error']['message']}');
    }
  }

  // Updated _writePrescription method - Bottom Sheet Style
  Future<void> _writePrescription(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true, // This makes it take most of the screen
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height:
                MediaQuery.of(context).size.height *
                0.9, // 90% of screen height
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: ProfessionalPrescriptionDialog(userId: widget.userId),
          ),
    );
  }

  /// ============= UPLOAD PRESCRIPTION FILE ==============
  Future<void> _uploadPrescription(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
    );

    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.first.path;
    final fileName = result.files.first.name;
    if (filePath == null) return;

    final file = File(filePath);

    try {
      final downloadUrl = await _uploadToCloudinary(file);

      await FirebaseFirestore.instance.collection('prescriptions').add({
        'userId': widget.userId,
        'title': fileName,
        'downloadUrl': downloadUrl,
        'uploadedBy': 'doctor',
        'type': 'file',
        'status': 'reviewed',
        'date': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prescription uploaded successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  /// ============= WRITE PRESCRIPTION (TEXT) ==============

  Future<void> _addPrescription(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.medical_services,
                            color: Colors.blue,
                            size: 28,
                          ),
                        ),
                        title: const Text(
                          'Add Prescription',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: const Text(
                          'Choose how you want to create the prescription',
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Options
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.edit_document,
                              color: Colors.green,
                              size: 24,
                            ),
                          ),
                          title: const Text(
                            'Write Digital Prescription',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: const Text(
                            'Create professional prescription form',
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () {
                            Navigator.pop(context); // Close options sheet
                            _writePrescription(
                              context,
                            ); // Open prescription popup
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.upload_file,
                              color: Colors.orange,
                              size: 24,
                            ),
                          ),
                          title: const Text(
                            'Upload Prescription File',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: const Text(
                            'Upload scanned document or image',
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () {
                            Navigator.pop(context); // Close options sheet
                            _uploadPrescription(context); // Open file picker
                          },
                        ),
                      ),

                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  /// ============= INFO ROW WIDGET ==============
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : "Not provided",
              style: TextStyle(color: Colors.grey[800], fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  /// ============= FILE SECTION BUILDER ==============
  Widget _buildFilesSection(
    String title,
    Stream<QuerySnapshot> stream,
    CollectionReference collectionRef,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 40, thickness: 1),
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Error loading documents.');
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data!.docs.isEmpty) {
              return Column(
                children: const [
                  Icon(Icons.folder_off, size: 60, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'No files available.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              );
            }

            return Column(
              children:
                  snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>? ?? {};

                    final type = (data['type'] ?? 'file') as String;
                    final title = (data['title'] ?? 'Untitled').toString();
                    final status = (data['status'] ?? 'pending').toString();
                    final date =
                        (data['date'] is Timestamp)
                            ? (data['date'] as Timestamp).toDate()
                            : DateTime.now();

                    final downloadUrl =
                        type == 'file'
                            ? (data['downloadUrl'] ?? '').toString()
                            : null;
                    final content =
                        type == 'text'
                            ? (data['content'] ?? '').toString()
                            : null;

                    return GestureDetector(
                      onTap: () {
                        // Only show bottom sheet for text prescriptions
                        if (type == 'text') {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder:
                                (context) => Container(
                                  height:
                                      MediaQuery.of(context).size.height *
                                      0.9, // 90% height
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                    ),
                                  ),
                                ),
                          );
                        }
                      },
                      child: PatientFileCard(
                        docId: doc.id,
                        title: title,
                        date: date,
                        status: status,
                        downloadUrl: downloadUrl ?? '',
                        content: content,
                        onDelete: () async {
                          await FirebaseFirestore.instance
                              .collection('prescriptions')
                              .doc(doc.id)
                              .delete();

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Prescription deleted successfully.',
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
            );
          },
        ),
      ],
    );
  }

  /// ============= MAIN BUILD METHOD ==============
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Patient's Details")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _uploadPrescription(context),
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload Documents'),
        tooltip: 'Upload a document for this patient',
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance
                .collection('users')
                .doc(widget.userId)
                .get(),
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
                // Personal Details
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personal Details',
                          style: theme.textTheme.titleLarge?.copyWith(
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
                        _infoRow(
                          'Address',
                          fullAddress.isNotEmpty ? fullAddress : 'Not provided',
                        ),
                      ],
                    ),
                  ),
                ),

                // Medical Info
                Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(top: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Medical Information',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _infoRow('Blood Group', data['bloodGroup'] ?? 'N/A'),
                        _infoRow('Allergies', data['allergies'] ?? 'N/A'),
                        _infoRow(
                          'Chronic Conditions',
                          data['chronicConditions'] ?? 'N/A',
                        ),
                        _infoRow('Medications', data['medications'] ?? 'N/A'),
                        _infoRow(
                          'Primary Doctor',
                          data['primaryDoctor'] ?? 'N/A',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: _requestService,
                  icon: const Icon(Icons.add_circle),
                  label: const Text("Request a Service"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),

                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _addPrescription(context),
                  icon: const Icon(Icons.medical_services),
                  label: const Text('Add Prescription'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),

                const SizedBox(height: 20),

                _buildFilesSection(
                  'Patient Uploaded Files',
                  FirebaseFirestore.instance
                      .collection('uploaded_files')
                      .where('userId', isEqualTo: widget.userId)
                      .snapshots(),
                  FirebaseFirestore.instance.collection('uploaded_files'),
                ),

                _buildFilesSection(
                  'Hospital Uploaded Files',
                  FirebaseFirestore.instance
                      .collection('doctor_uploaded_files')
                      .where('userId', isEqualTo: widget.userId)
                      .snapshots(),
                  FirebaseFirestore.instance.collection(
                    'doctor_uploaded_files',
                  ),
                ),

                _buildFilesSection(
                  'Prescriptions',
                  FirebaseFirestore.instance
                      .collection('prescriptions')
                      .where('userId', isEqualTo: widget.userId)
                      .snapshots(),
                  FirebaseFirestore.instance.collection('prescriptions'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
