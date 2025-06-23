import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'dark_mode.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _remindersEnabled = true;
  bool _darkModeEnabled = false;

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text('Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Password'),
            onTap: () {
              // Navigate to Change Password screen
            },
          ),
          const Divider(),

          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: const Text('Appointment Reminders'),
            value: _remindersEnabled,
            onChanged: (val) => setState(() => _remindersEnabled = val),
          ),
          const Divider(),

          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text('App Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: Provider.of<ThemeNotifier>(context).themeMode == ThemeMode.dark,
            onChanged: (val) {
              Provider.of<ThemeNotifier>(context, listen: false).toggleTheme(val);
              setState(() {
                _darkModeEnabled = val;
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App Version'),
            subtitle: const Text('v1.0.0'),
          ),
          const Divider(),

          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text('Help & Support', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('FAQs'),
            onTap: () {
              // Navigate to FAQs
            },
          ),
          ListTile(
            leading: const Icon(Icons.phone),
            title: const Text('Contact Support'),
            onTap: () {
              // Navigate to Contact Support screen
            },
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}
