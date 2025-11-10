import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../firebase_auth/signin.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Personal info
  String fullName = '';
  String email = '';
  String? profilePicture;
  String role = '';
  String phone = '';
  String nextOfKin = '';
  String nextOfKinPhone = '';
  String address = '';
  String id = "";
  String dob = '';
  String gender = '';

  // Medical info
  String bloodGroup = '';
  String allergies = '';
  String chronicConditions = '';
  String medications = '';
  String primaryDoctor = '';

  // Professional info
  String specialty = '';
  String hospital = '';
  String licenseNumber = '';

  bool _isLoading = true;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (pickedFile == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final file = File(pickedFile.path);
      final cloudinaryUploadUrl = Uri.parse(
        'https://api.cloudinary.com/v1_1/dzz3iovq5/image/upload', // Changed to image upload
      );

      final request =
          http.MultipartRequest('POST', cloudinaryUploadUrl)
            ..fields['upload_preset'] = 'ehospital'
            ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final resStr = await response.stream.bytesToString();
        final data = json.decode(resStr);
        final secureUrl = data['secure_url'];

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'profilePicture': secureUrl});

          setState(() {
            profilePicture = secureUrl;
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Profile picture updated successfully"),
              backgroundColor: Color(0xFF00796B),
            ),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to upload image"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error uploading image: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (doc.exists) {
          final data = doc.data()!;
          final addressData = data['address'] as Map<String, dynamic>? ?? {};
          final medicalData =
              data['medicalInfo'] as Map<String, dynamic>? ?? {};

          setState(() {
            fullName = data['fullName'] ?? data['name'] ?? 'Not provided';
            email = user.email ?? 'Not provided';
            profilePicture = data['profilePicture'];
            role = data['role'] ?? 'patient';
            phone = data['phone'] ?? 'Not provided';
            id = data['id'] ?? 'Not provided';
            gender = data['gender']?.toString().capitalize() ?? 'Not provided';

            nextOfKin = data['nextOfKin'] ?? 'Not provided';
            nextOfKinPhone = data['nextOfKinPhone'] ?? 'Not provided';

            // Better address formatting
            address = _formatAddress(addressData);

            // Parse DOB from ID or use direct DOB field
            dob = data['dateOfBirth'] ?? _parseDobFromId(id);

            // Medical info
            bloodGroup = medicalData['bloodGroup'] ?? 'Not provided';
            allergies = medicalData['allergies'] ?? 'None';
            chronicConditions = medicalData['chronicConditions'] ?? 'None';
            medications = medicalData['medications'] ?? 'None';
            primaryDoctor = medicalData['primaryDoctor'] ?? 'Not assigned';

            // Professional info
            specialty = data['specialty'] ?? 'Not specified';
            hospital = data['hospitalName'] ?? 'Not assigned';
            licenseNumber = data['licenseNumber'] ?? 'Not provided';

            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          _showErrorDialog('User data not found');
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Error loading profile: ${e.toString()}');
      }
    }
  }

  String _formatAddress(Map<String, dynamic> addressData) {
    if (addressData.isEmpty) return 'Not provided';

    final parts =
        [
          addressData['street'],
          addressData['city'],
          addressData['province'],
          addressData['postalCode'],
          addressData['country'],
        ].where((part) => part != null && part.toString().isNotEmpty).toList();

    return parts.isNotEmpty ? parts.join(', ') : 'Not provided';
  }

  String _parseDobFromId(String idNumber) {
    if (idNumber.length < 6 || idNumber == 'Not provided')
      return 'Not provided';

    try {
      final year = int.parse(idNumber.substring(0, 2));
      final month = int.parse(idNumber.substring(2, 4));
      final day = int.parse(idNumber.substring(4, 6));

      // Validate date
      if (month < 1 || month > 12 || day < 1 || day > 31) {
        return 'Not provided';
      }

      final currentYear = DateTime.now().year;
      final century = (year > currentYear % 100) ? 1900 : 2000;
      final fullYear = century + year;

      final date = DateTime(fullYear, month, day);

      // Check if date is in future (invalid)
      if (date.isAfter(DateTime.now())) {
        return 'Not provided';
      }

      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (e) {
      return 'Not provided';
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showEditProfileDialog() {
    final phoneController = TextEditingController(
      text: phone != 'Not provided' ? phone : '',
    );
    final nextOfKinController = TextEditingController(
      text: nextOfKin != 'Not provided' ? nextOfKin : '',
    );
    final nextOfKinPhoneController = TextEditingController(
      text: nextOfKinPhone != 'Not provided' ? nextOfKinPhone : '',
    );

    // Get address parts
    final addressData = _getAddressParts();
    final streetController = TextEditingController(
      text: addressData['street'] ?? '',
    );
    final cityController = TextEditingController(
      text: addressData['city'] ?? '',
    );
    final provinceController = TextEditingController(
      text: addressData['province'] ?? '',
    );
    final postalCodeController = TextEditingController(
      text: addressData['postalCode'] ?? '',
    );
    final countryController = TextEditingController(
      text: addressData['country'] ?? '',
    );

    // Medical info controllers
    final bloodGroupController = TextEditingController(
      text: bloodGroup != 'Not provided' ? bloodGroup : '',
    );
    final allergiesController = TextEditingController(
      text: allergies != 'None' ? allergies : '',
    );
    final chronicConditionsController = TextEditingController(
      text: chronicConditions != 'None' ? chronicConditions : '',
    );
    final medicationsController = TextEditingController(
      text: medications != 'None' ? medications : '',
    );
    final primaryDoctorController = TextEditingController(
      text: primaryDoctor != 'Not assigned' ? primaryDoctor : '',
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'Edit Profile Information',
              style: TextStyle(color: Color(0xFF00796B)),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Personal Details Section
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Personal Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00796B),
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    phoneController,
                    'Phone Number',
                    TextInputType.phone,
                  ),
                  _buildTextField(nextOfKinController, 'Next of Kin'),
                  _buildTextField(
                    nextOfKinPhoneController,
                    'Next of Kin Phone',
                    TextInputType.phone,
                  ),

                  // Address Section
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Address',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00796B),
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(streetController, 'Street'),
                  _buildTextField(cityController, 'City'),
                  _buildTextField(provinceController, 'Province'),
                  _buildTextField(
                    postalCodeController,
                    'Postal Code',
                    TextInputType.number,
                  ),
                  _buildTextField(countryController, 'Country'),

                  // Medical Information Section (only for patients)
                  if (role != 'doctor') ...[
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Medical Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00796B),
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(bloodGroupController, 'Blood Group'),
                    _buildTextField(
                      allergiesController,
                      'Allergies',
                      TextInputType.multiline,
                    ),
                    _buildTextField(
                      chronicConditionsController,
                      'Chronic Conditions',
                      TextInputType.multiline,
                    ),
                    _buildTextField(
                      medicationsController,
                      'Current Medications',
                      TextInputType.multiline,
                    ),
                    _buildTextField(primaryDoctorController, 'Primary Doctor'),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00796B),
                ),
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    try {
                      final addressData = {
                        'street': streetController.text.trim(),
                        'city': cityController.text.trim(),
                        'province': provinceController.text.trim(),
                        'postalCode': postalCodeController.text.trim(),
                        'country': countryController.text.trim(),
                      };

                      final medicalData = {
                        'bloodGroup': bloodGroupController.text.trim(),
                        'allergies': allergiesController.text.trim(),
                        'chronicConditions':
                            chronicConditionsController.text.trim(),
                        'medications': medicationsController.text.trim(),
                        'primaryDoctor': primaryDoctorController.text.trim(),
                      };

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .update({
                            'phone': phoneController.text.trim(),
                            'nextOfKin': nextOfKinController.text.trim(),
                            'nextOfKinPhone':
                                nextOfKinPhoneController.text.trim(),
                            'address': addressData,
                            if (role != 'doctor') 'medicalInfo': medicalData,
                          });

                      if (!mounted) return;
                      Navigator.pop(context);
                      _loadUserData();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Profile updated successfully"),
                          backgroundColor: Color(0xFF00796B),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Error updating profile: ${e.toString()}",
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  'Save Changes',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  Map<String, String> _getAddressParts() {
    if (address == 'Not provided') return {};

    final parts = address.split(',');
    return {
      'street': parts.length > 0 ? parts[0].trim() : '',
      'city': parts.length > 1 ? parts[1].trim() : '',
      'province': parts.length > 2 ? parts[2].trim() : '',
      'postalCode': parts.length > 3 ? parts[3].trim() : '',
      'country': parts.length > 4 ? parts[4].trim() : '',
    };
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, [
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  ]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF00796B)),
          border: const OutlineInputBorder(),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF00796B), width: 2),
          ),
          isDense: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDoctor = role == 'doctor';

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFE0F2F1),
        appBar: AppBar(
          title: const Text(
            'My Profile',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF00796B),
          centerTitle: true,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF00796B)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE0F2F1),
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF00796B),
        centerTitle: true,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _showEditProfileDialog,
            tooltip: 'Edit Profile',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadUserData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          // Profile Header
          Center(
            child: Stack(
              children: [
                _isUploadingImage
                    ? Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00796B).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const CircularProgressIndicator(
                        color: Color(0xFF00796B),
                      ),
                    )
                    : CircleAvatar(
                      radius: 60,
                      backgroundColor: const Color(0xFF00796B).withOpacity(0.1),
                      backgroundImage:
                          profilePicture != null && profilePicture!.isNotEmpty
                              ? NetworkImage(profilePicture!)
                              : null,
                      child:
                          (profilePicture == null || profilePicture!.isEmpty)
                              ? Text(
                                fullName.isNotEmpty
                                    ? fullName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 40,
                                  color: Color(0xFF00796B),
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                              : null,
                    ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _isUploadingImage ? null : _pickAndUploadImage,
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            _isUploadingImage
                                ? Colors.grey
                                : const Color(0xFF00796B),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        _isUploadingImage
                            ? Icons.hourglass_top
                            : Icons.camera_alt,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Center(
            child: Text(
              fullName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF00796B),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              email,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00796B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                role.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF00796B),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Personal Details Container
          _buildInfoContainer(
            title: 'Personal Details',
            children: [
              _infoRow('ID Number', id),
              _infoRow('Gender', gender),
              _infoRow('Date of Birth', dob),
              _infoRow('Phone Number', phone),
              if (!isDoctor) ...[
                _infoRow('Next of Kin', nextOfKin),
                if (nextOfKinPhone != 'Not provided')
                  _infoRow('Kin Phone', nextOfKinPhone),
              ],
              _infoRow('Address', address),
            ],
          ),

          // Professional/Medical Info Container
          _buildInfoContainer(
            title:
                isDoctor ? 'Professional Information' : 'Medical Information',
            children:
                isDoctor
                    ? [
                      _infoRow('Specialty', specialty),
                      _infoRow('Hospital', hospital),
                      _infoRow('License Number', licenseNumber),
                    ]
                    : [
                      _infoRow('Blood Group', bloodGroup),
                      _infoRow('Allergies', allergies),
                      _infoRow('Chronic Conditions', chronicConditions),
                      _infoRow('Current Medications', medications),
                      _infoRow('Primary Doctor', primaryDoctor),
                    ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoContainer({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00796B).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00796B),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    final isEmpty =
        value.isEmpty ||
        value == 'Not provided' ||
        value == 'None' ||
        value == 'Not assigned';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Color(0xFF00796B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              isEmpty ? "Not provided" : value,
              style: TextStyle(
                fontSize: 15,
                color: isEmpty ? Colors.grey.shade500 : Colors.grey.shade800,
                fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
