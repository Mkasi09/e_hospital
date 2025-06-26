import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  String specialty = '';
  String hospital = '';
  String licenseNumber = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        final addressData = data['address'] as Map<String, dynamic>?;
        final medicalData = data['medicalInfo'] as Map<String, dynamic>? ?? {};

        setState(() {
          fullName = data['fullName'] ?? data['name'] ?? '';
          email = user.email ?? '';
          profilePicture = data['profilePicture'];
          role = data['role'] ?? '';
          phone = data['phone'] ?? '';
          id = data['id'] ?? '';
          gender = data['gender'] ?? '';
          dob = _parseDobFromId(id);

          nextOfKin = data['nextOfKin'] ?? '';
          nextOfKinPhone = data['nextOfKinPhone'] ?? '';

          address = addressData != null
              ? '${addressData['street'] ?? ''}, ${addressData['city'] ?? ''}, ${addressData['province'] ?? ''}, ${addressData['postalCode'] ?? ''}, ${addressData['country'] ?? ''}'
              : '';

          bloodGroup = medicalData['bloodGroup'] ?? '';
          allergies = medicalData['allergies'] ?? '';
          chronicConditions = medicalData['chronicConditions'] ?? '';
          medications = medicalData['medications'] ?? '';
          primaryDoctor = medicalData['primaryDoctor'] ?? '';

          specialty = data['specialty'] ?? '';
          hospital = data['hospitalName'] ?? '';
          licenseNumber = data['licenseNumber'] ?? '';

          _isLoading = false;
        });
      }
    }
  }

  String _parseDobFromId(String idNumber) {
    if (idNumber.length < 6) return '';

    try {
      final year = int.parse(idNumber.substring(0, 2));
      final month = int.parse(idNumber.substring(2, 4));
      final day = int.parse(idNumber.substring(4, 6));

      final currentYear = DateTime.now().year;
      final century = (year > currentYear % 100) ? 1900 : 2000;
      final fullYear = century + year;

      final date = DateTime(fullYear, month, day);
      return "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
    } catch (e) {
      return '';
    }
  }

  void _showEditProfileDialog() {
    final phoneController = TextEditingController(text: phone);
    final nextOfKinController = TextEditingController(text: nextOfKin);
    final nextOfKinPhoneController = TextEditingController(text: nextOfKinPhone);

    // Parse address parts or use empty strings
    final parts = address.split(',').map((e) => e.trim()).toList();
    final streetController = TextEditingController(text: parts.isNotEmpty ? parts[0] : '');
    final cityController = TextEditingController(text: parts.length > 1 ? parts[1] : '');
    final provinceController = TextEditingController(text: parts.length > 2 ? parts[2] : '');
    final postalCodeController = TextEditingController(text: parts.length > 3 ? parts[3] : '');
    final countryController = TextEditingController(text: parts.length > 4 ? parts[4] : '');

    // Medical info controllers
    final bloodGroupController = TextEditingController(text: bloodGroup);
    final allergiesController = TextEditingController(text: allergies);
    final chronicConditionsController = TextEditingController(text: chronicConditions);
    final medicationsController = TextEditingController(text: medications);
    final primaryDoctorController = TextEditingController(text: primaryDoctor);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Personal & Medical Info'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Personal Details', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildTextField(phoneController, 'Phone Number', TextInputType.phone),
              _buildTextField(nextOfKinController, 'Next of Kin'),
              _buildTextField(nextOfKinPhoneController, 'Next of Kin Phone', TextInputType.phone),
              const SizedBox(height: 12),
              _buildTextField(streetController, 'Street'),
              _buildTextField(cityController, 'City'),
              _buildTextField(provinceController, 'Province'),
              _buildTextField(postalCodeController, 'Postal Code', TextInputType.number),
              _buildTextField(countryController, 'Country'),
              const Divider(height: 32),
              const Text('Medical Information', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildTextField(bloodGroupController, 'Blood Group'),
              _buildTextField(allergiesController, 'Allergies', TextInputType.multiline,),
              _buildTextField(chronicConditionsController, 'Chronic Conditions', TextInputType.multiline,),
              _buildTextField(medicationsController, 'Medications', TextInputType.multiline,),
              _buildTextField(primaryDoctorController, 'Primary Doctor'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
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
                  'chronicConditions': chronicConditionsController.text.trim(),
                  'medications': medicationsController.text.trim(),
                  'primaryDoctor': primaryDoctorController.text.trim(),
                };

                await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                  'phone': phoneController.text.trim(),
                  'nextOfKin': nextOfKinController.text.trim(),
                  'nextOfKinPhone': nextOfKinPhoneController.text.trim(),
                  'address': addressData,
                  'medicalInfo': medicalData,
                });

                Navigator.pop(context);
                _loadUserData();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      [TextInputType keyboardType = TextInputType.text, int maxLines = 1]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
  Widget _buildMedicalInfoCard() {
    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Medical Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 16),
          _infoRow('Blood Group', bloodGroup),
          _infoRow('Allergies', allergies),
          _infoRow('Chronic Conditions', chronicConditions),
          _infoRow('Medications', medications),
          _infoRow('Primary Doctor', primaryDoctor),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final isDoctor = 'doctor';

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          backgroundColor: Colors.blue.shade800,
          centerTitle: true,
          elevation: 1,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.blue.shade800,
        centerTitle: true,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditProfileDialog,
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: profilePicture != null && profilePicture!.isNotEmpty
                  ? NetworkImage(profilePicture!)
                  : null,
              child: (profilePicture == null || profilePicture!.isEmpty)
                  ? Text(
                fullName.isNotEmpty ? fullName[0].toUpperCase() : '',
                style: const TextStyle(fontSize: 40, color: Colors.white),
              )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              fullName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              email,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Personal Details Container
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personal Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                _infoRow('ID Number', id),
                _infoRow('Gender', gender),
                _infoRow('Date of Birth', dob),
                _infoRow('Phone Number', phone),
    if (role!=isDoctor) ...[
                _infoRow(
                  'Next of Kin',
                  nextOfKin.isNotEmpty
                      ? (nextOfKinPhone.isNotEmpty ? '$nextOfKin ($nextOfKinPhone)' : nextOfKin)
                      : '',
                ),
                _infoRow('Address', address),
              ],
    ]
            ),
          ),

          // Medical Info Container
          Container(
            margin: const EdgeInsets.only(top: 32),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role=='doctor' ? 'Professional Information' : 'Medical Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                if (role==isDoctor) ...[
                  _infoRow('Specialty', specialty),
                  _infoRow('Hospital', hospital),
                  _infoRow('License No.', licenseNumber),
                ] else ...[
                  _infoRow('Next of Kin', nextOfKin),
                  _infoRow('Kin Phone', nextOfKinPhone),
                  _infoRow('Blood Group', bloodGroup),
                  _infoRow('Allergies', allergies),
                  _infoRow('Chronic Conditions', chronicConditions),
                  _infoRow('Medications', medications),
                  _infoRow('Primary Doctor', primaryDoctor),
                ],
              ],
            ),
          ),

          const SizedBox(height: 40),

          _buildProfileOption(
            icon: Icons.lock_outline,
            label: 'Change Password',
            onTap: () {
              // TODO: Implement change password screen
            },
          ),
          _buildProfileOption(
            icon: Icons.logout,
            label: 'Logout',
            iconColor: Colors.red.shade600,
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : "Not provided",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 5,
      shadowColor: Colors.black26,
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? Colors.blue.shade800),
        title: Text(
          label,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey.shade500),
        onTap: onTap,
      ),
    );
  }
}

Future<void> _logout(BuildContext context) async {
  await FirebaseAuth.instance.signOut();
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (context) => LoginPage()),
        (route) => false,
  );
}
