import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  bool _remindersEnabled = false;
  String _reminderTime = '30 minutes';
  final List<String> _reminderOptions = ['15 minutes', '30 minutes', '1 hour', '1 day'];

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        _remindersEnabled = data['appointmentRemindersEnabled'] ?? false;
        _reminderTime = data['reminderTimeBefore'] ?? '30 minutes';
      });
    }
  }

  Future<void> _saveSettings() async {
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'appointmentRemindersEnabled': _remindersEnabled,
      'reminderTimeBefore': _reminderTime,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reminder settings saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appointment Reminders')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Enable Reminders'),
              value: _remindersEnabled,
              onChanged: (value) {
                setState(() => _remindersEnabled = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Remind me before',
                border: OutlineInputBorder(),
              ),
              value: _reminderTime,
              items: _reminderOptions.map((option) {
                return DropdownMenuItem(value: option, child: Text(option));
              }).toList(),
              onChanged: _remindersEnabled
                  ? (value) => setState(() => _reminderTime = value!)
                  : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text('Save Settings'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
          ],
        ),
      ),
    );
  }
}
