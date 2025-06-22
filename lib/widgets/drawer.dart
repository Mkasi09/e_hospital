import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:e_hospital/screens/profile/profile.dart';
import 'package:provider/provider.dart';
import '../screens/settings/doctor_settings_screen.dart';

class PatientDrawer extends StatefulWidget {
  const PatientDrawer({super.key});

  @override
  State<PatientDrawer> createState() => _PatientDrawerState();
}

class _PatientDrawerState extends State<PatientDrawer> {
  bool isDarkMode = false;

  Future<Map<String, String>> _fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {'fullName': 'Patient', 'profileImageUrl': ''};

    final snapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (snapshot.exists) {
      final data = snapshot.data()!;
      return {
        'fullName': data['fullName'] ?? 'Patient',
        'profileImageUrl': data['profileImageUrl'] ?? '',
      };
    }
    return {'fullName': 'Patient', 'profileImageUrl': ''};
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder<Map<String, String>>(
        future: _fetchUserData(),
        builder: (context, snapshot) {
          final fullName = snapshot.data?['fullName'] ?? 'Patient';
          final profileImageUrl = snapshot.data?['profileImageUrl'] ?? '';

          return Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF21CBF3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                width: double.infinity,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl)
                          : null,
                      backgroundColor: Colors.white,
                      child: profileImageUrl.isEmpty
                          ? const Icon(Icons.person, size: 30, color: Colors.blue)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Welcome,\n$fullName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    _buildDrawerCard(
                      icon: Icons.notifications_none,
                      label: 'Notifications',
                      onTap: () => Navigator.pushNamed(context, '/notifications'),
                    ),
                    _buildDrawerCard(
                      icon: Icons.person_outline,
                      label: 'My Profile',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileScreen()),
                        );
                      },
                    ),
                    _buildDrawerCard(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        );
                      },
                    ),
                    _buildDrawerCard(
                      icon: Icons.description_outlined,
                      label: 'Terms & Conditions',
                      onTap: () => Navigator.pushNamed(context, '/terms'),
                    ),


                    const Divider(height: 30, thickness: 1),
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
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  "e-Hospital App v1.0",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              )
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            children: [
              Icon(icon, size: 26, color: iconColor ?? Colors.blue.shade700),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              const Icon(Icons.chevron_right, size: 22, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
