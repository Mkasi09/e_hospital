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
  String fullName = 'Loading...';
  String email = '';
  String? profilePicture;
  String userType = '';
  String phone = '';
  String nextOfKin = '';
  String address = '';
  String id = "";
  String dob = '';
  String gender = '';
  String nextOfKinPhone = '';
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  void _showEditAddressDialog() {
    final streetController = TextEditingController();
    final cityController = TextEditingController();
    final provinceController = TextEditingController();
    final postalCodeController = TextEditingController();
    final countryController = TextEditingController();

    final phoneController = TextEditingController(text: phone);
    final nextOfKinController = TextEditingController(text: nextOfKin);

    // Pre-fill address fields by splitting existing address string
    final parts = address.split(',').map((e) => e.trim()).toList();
    if (parts.length >= 5) {
      streetController.text = parts[0];
      cityController.text = parts[1];
      provinceController.text = parts[2];
      postalCodeController.text = parts[3];
      countryController.text = parts[4];
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Personal Details'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              TextField(
                controller: nextOfKinController,
                decoration: const InputDecoration(labelText: 'Next of Kin'),
              ),
              const Divider(height: 32),
              TextField(
                controller: streetController,
                decoration: const InputDecoration(labelText: 'Street'),
              ),
              TextField(
                controller: cityController,
                decoration: const InputDecoration(labelText: 'City'),
              ),
              TextField(
                controller: provinceController,
                decoration: const InputDecoration(labelText: 'Province'),
              ),
              TextField(
                controller: postalCodeController,
                decoration: const InputDecoration(labelText: 'Postal Code'),
              ),
              TextField(
                controller: countryController,
                decoration: const InputDecoration(labelText: 'Country'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
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
                await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                  'phone': phoneController.text.trim(),
                  'nextOfKin': nextOfKinController.text.trim(),
                  'address': addressData,
                });
                Navigator.pop(context);
                _loadUserData(); // Refresh UI
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }


  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (snapshot.exists) {
        final data = snapshot.data()!;
        final addressData = data['address'] as Map<String, dynamic>?;

        setState(() {
          fullName = data['fullName'] ?? 'No Name';
          email = user.email ?? '';
          userType = data['userType'] ?? 'patient';
          phone = data['phone'] ?? '';
          nextOfKin = data['nextOfKin'] ?? '';
          id = data['id'] ?? '';
          nextOfKinPhone = data['nextOfKin\'sPhone'] ?? '';
          gender = data['gender'] ?? '';
          dob = data['dob'] ?? '';
          address = addressData != null
              ? '${addressData['street'] ?? ''}, ${addressData['city'] ?? ''}, ${addressData['province'] ?? ''}, ${addressData['postalCode'] ?? ''}, ${addressData['country'] ?? ''}'
              : 'No address provided';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDoctor = userType.toLowerCase() == 'doctor';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        color: Colors.grey[100],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (isDoctor && profilePicture != null)
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(profilePicture!),
                ),
              if (isDoctor && profilePicture != null)
                const SizedBox(height: 16),

              Text(
                fullName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 24),
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
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Personal Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blueAccent),
                          onPressed: _showEditAddressDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _infoRow('ID Number', id),
                    _infoRow('Gender', gender),
                    _infoRow('Date of birthday', dob),
                    _infoRow('Phone Number', phone),
                    _infoRow('Next of Kin', nextOfKin+'(nextOfKin\'sPhone)'),
                    _infoRow('Address', address),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              _buildProfileOption(
                icon: Icons.lock,
                label: 'Change Password',
                onTap: () {
                  // TODO: Navigate to change password screen
                },
              ),
              _buildProfileOption(
                icon: Icons.logout,
                label: 'Logout',
                iconColor: Colors.red,
                onTap: () => _logout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

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

  Widget _buildProfileOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? Colors.blueAccent),
        title: Text(
          label,
          style: const TextStyle(fontSize: 16),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
