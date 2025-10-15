import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_auth/signin.dart';
import '../screens/profile/profile.dart';
import '../screens/settings/about_screen.dart';
import '../screens/settings/doctor_settings_screen.dart';
import '../screens/settings/help_faq_screen.dart';
import '../screens/settings/terms_and_conditons.dart';

class RoleBasedDrawer extends StatelessWidget {
  const RoleBasedDrawer({super.key});

  Future<Map<String, dynamic>> _fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return {
        'displayName': 'User',
        'profileUrl': null,
        'onlineStatus': false,
        'role': 'unknown',
      };
    }

    // Check cached role first
    final prefs = await SharedPreferences.getInstance();
    String? cachedRole = prefs.getString('userRole');

    final snapshot =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (snapshot.exists) {
      final data = snapshot.data()!;
      final role = data['role'] ?? cachedRole ?? 'unknown';
      await prefs.setString('userRole', role);

      // Pick name field based on role
      final displayName =
          role == 'doctor'
              ? (data['name'] ?? 'Doctor')
              : (data['fullName'] ?? 'Patient');

      return {
        'displayName': displayName,
        'profileUrl': data['profilePicture'],
        'onlineStatus': data['onlineStatus'] ?? false,
        'role': role,
      };
    } else {
      return {
        'displayName': 'User',
        'profileUrl': null,
        'onlineStatus': false,
        'role': cachedRole ?? 'unknown',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF8F9FA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      elevation: 16,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _fetchUserData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final displayName = data['displayName'] ?? 'User';
          final profileUrl = data['profileUrl'];
          final onlineStatus = data['onlineStatus'] ?? false;
          final role = data['role'] ?? 'unknown';

          return Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  top: 56,
                  left: 24,
                  right: 24,
                  bottom: 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.teal.shade100,
                                  width: 3,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 32,
                                backgroundColor: Colors.teal.shade50,
                                backgroundImage:
                                    profileUrl != null
                                        ? NetworkImage(profileUrl)
                                        : null,
                                child:
                                    profileUrl == null
                                        ? Icon(
                                          Icons.person,
                                          color: Colors.teal.shade200,
                                          size: 36,
                                        )
                                        : null,
                              ),
                            ),
                            if (onlineStatus)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 18,
                                  height: 18,
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome,',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      role == 'doctor' ? 'Doctor Account' : 'Patient Account',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.teal.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Menu items based on role
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildDrawerItem(
                      context,
                      icon: Icons.person_outline,
                      label: 'My Profile',
                      color: Colors.teal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        );
                      },
                    ),
                    if (role == 'patient') ...[
                      _buildDrawerItem(
                        context,
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                        color: Colors.blue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ] else if (role == 'doctor') ...[
                      _buildDrawerItem(
                        context,
                        icon: Icons.medical_services_outlined,
                        label: 'Doctor Settings',
                        color: Colors.indigo,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                    _buildDrawerItem(
                      context,
                      icon: Icons.description_outlined,
                      label: 'Terms & Conditions',
                      color: Colors.indigo,
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
                    _buildDrawerItem(
                      context,
                      icon: Icons.help_outline,
                      label: 'Help & FAQ',
                      color: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HelpFaqScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.info_outline,
                      label: 'About',
                      color: Colors.blueGrey,
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

              // Logout button
              Container(
                padding: const EdgeInsets.all(16),
                child: _buildDrawerItem(
                  context,
                  icon: Icons.logout,
                  label: 'Logout',
                  color: Colors.red,
                  onTap: () => _logout(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Card(
      color: const Color(0xFFE0F2F1),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey.shade400,
        ),
        onTap: onTap,
      ),
    );
  }
}

Future<void> _logout(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('userRole'); // clear cached role
  await FirebaseAuth.instance.signOut();

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (context) => const LoginPage()),
    (route) => false,
  );
}
