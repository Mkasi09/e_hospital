import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_hospital/screens/profile/profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/settings/doctor_settings_screen.dart';

class PatientDrawer extends StatelessWidget {
  const PatientDrawer({super.key});

  Future<String> _fetchFullName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 'Patient';

    final snapshot =
    await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (snapshot.exists && snapshot.data()!.containsKey('fullName')) {
      return snapshot['fullName'];
    } else {
      return 'Patient';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder<String>(
        future: _fetchFullName(),
        builder: (context, snapshot) {
          final fullName = snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData
              ? snapshot.data!
              : 'Patient';

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Welcome,\n$fullName',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    _buildDrawerCard(
                      icon: Icons.person,
                      label: 'My Profile',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileScreen()),
                        );
                      },
                    ),
                    _buildDrawerCard(
                      icon: Icons.settings,
                      label: 'Settings',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        );
                      },
                    ),
                    _buildDrawerCard(
                      icon: Icons.description,
                      label: 'Terms & Conditions',
                      onTap: () => Navigator.pushNamed(context, '/terms'),
                    ),
                    const SizedBox(height: 12),
                    _buildDrawerCard(
                      icon: Icons.logout,
                      label: 'Logout',
                      iconColor: Colors.red,
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawerCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            children: [
              Icon(icon, size: 28, color: iconColor ?? Colors.blue.shade700),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
