import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_hospital/screens/doctor/appointments/patients_appointments.dart';
import 'package:e_hospital/screens/doctor/chats/doctor_inbox.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../widgets/drawer.dart';
import '../../../widgets/home_tile.dart';
import '../../patient/my_appointments/appointments.dart';
import '../doctors_notifications/doctors_notification_screen.dart';
import '../doctors_notifications/notification_bell.dart';
import '../patients/Doctors_patient_screen.dart';
import '../schedule/schedule_screen.dart';

class DoctorsHomepage extends StatefulWidget {
  const DoctorsHomepage({super.key});

  @override
  State<DoctorsHomepage> createState() => _DoctorsHomepageState();
}

class _DoctorsHomepageState extends State<DoctorsHomepage> {
  String? _doctorName;
  String? profileUrl = 'null'; // Use a default URL or null
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDoctorName();
  }

  Future<void> _fetchDoctorName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _doctorName = data['name'] ?? 'Doctor';
             profileUrl = data['profilePicture'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _doctorName = 'Doctor';
            profileUrl = 'null';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _doctorName = 'Doctor';
        profileUrl = 'null';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        actions: [
          NotificationBell(
            userId: FirebaseAuth.instance.currentUser!.uid,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationScreen()),
              );
            },
          ),
        ],
      ),
      drawer: const PatientDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, $_doctorName!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Center(
              child: CircleAvatar(
                radius: 48,
                backgroundColor: Colors.blue,
                backgroundImage: profileUrl != null ? NetworkImage(profileUrl!) : null,
                child: profileUrl == null
                    ? const Icon(Icons.person, color: Colors.white, size: 36)
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  DashboardCard(
                    icon: Icons.calendar_today,
                    label: 'Appointments',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DoctorAppointments(),
                        ),
                      );
                    },
                  ),
                  DashboardCard(
                    icon: Icons.people,
                    label: 'Patients',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PatientsScreen(),
                        ),
                      );
                    },
                  ),
                  DashboardCard(
                    icon: Icons.schedule,
                    label: 'My Schedule',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  const ScheduleScreen(), // assuming no arguments needed
                        ),
                      );
                    },
                  ),
                  DashboardCard(
                    icon: Icons.chat,
                    label: 'Messages',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  const InboxScreen(), // assuming no arguments needed
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
