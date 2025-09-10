import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_hospital/screens/settings/about_screen.dart';
import 'package:e_hospital/screens/settings/terms_and_conditons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../firebase_auth/signin.dart';
import '../screens/profile/profile.dart';
import '../screens/settings/doctor_settings_screen.dart';
import '../screens/settings/help_faq_screen.dart';

class PatientDrawer extends StatelessWidget {
  const PatientDrawer({super.key});

  Future<Map<String, dynamic>> _fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return {'fullName': 'Patient', 'profileUrl': null, 'onlineStatus': false};
    }

    final snapshot =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (snapshot.exists) {
      final data = snapshot.data()!;
      return {
        'fullName': data['name'] ?? 'Patient',
        'profileUrl': data['profilePicture'],
        'onlineStatus': data['onlineStatus'] ?? false,
      };
    } else {
      return {'fullName': 'Patient', 'profileUrl': null, 'onlineStatus': false};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder<Map<String, dynamic>>(
        future: _fetchUserData(),
        builder: (context, snapshot) {
          final fullName =
              snapshot.hasData ? snapshot.data!['fullName'] : 'Patient';
          final profileUrl =
              snapshot.hasData ? snapshot.data!['profileUrl'] : null;
          final onlineStatus =
              snapshot.hasData
                  ? snapshot.data!['onlineStatus'] ?? false
                  : false;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 32,
                ),
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.teal.shade400,
                          backgroundImage:
                              profileUrl != null
                                  ? NetworkImage(profileUrl)
                                  : null,
                          child:
                              profileUrl == null
                                  ? const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 36,
                                  )
                                  : null,
                        ),
                        if (onlineStatus)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
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
                      iconColor: Colors.teal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerCard(
                      icon: Icons.settings,
                      label: 'Settings',
                      iconColor: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerCard(
                      icon: Icons.description,
                      label: 'Terms & Conditions',
                      iconColor: Colors.indigo,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => const TermsAndConditionsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerCard(
                      icon: Icons.help_outline,
                      label: 'Help & FAQ',
                      iconColor: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HelpFaqScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerCard(
                      icon: Icons.info,
                      label: 'About',
                      iconColor: Colors.blueGrey,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AboutScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Divider(thickness: 1.2),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 12,
                ),
                child: _buildDrawerCard(
                  icon: Icons.logout,
                  label: 'Logout',
                  iconColor: Colors.red,
                  onTap: () => _logout(context),
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
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            children: [
              Icon(icon, size: 28, color: iconColor ?? Colors.teal),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
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
