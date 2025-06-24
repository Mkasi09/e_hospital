import 'package:flutter/material.dart';

class PatientDrawer extends StatelessWidget {
  const PatientDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final String userName = "Nikita M.";
    final String profileImageUrl = "https://example.com/p2.png";

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              width: double.infinity,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundImage: NetworkImage(profileImageUrl),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildDrawerItem(
              icon: Icons.person_outline,
              title: 'Profile',
              onTap: () {
                Navigator.pushNamed(context, '/patientProfile');
              },
            ),
            _buildDrawerItem(
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
            _buildDrawerItem(
              icon: Icons.description_outlined,
              title: 'Terms & Conditions',
              onTap: () {
                Navigator.pushNamed(context, '/terms');
              },
            ),
            const Spacer(),
            Divider(),
            _buildDrawerItem(
              icon: Icons.logout,
              title: 'Logout',
              onTap: () {
                // Example: FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
              iconColor: Colors.red,
              textColor: Colors.red,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = Colors.black87,
    Color textColor = Colors.black87,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 26),
      title: Text(
        title,
        style: TextStyle(fontSize: 16, color: textColor),
      ),
      onTap: onTap,
      horizontalTitleGap: 0,
    );
  }
}
