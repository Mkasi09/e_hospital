import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_hospital/screens/doctor/appointments/patients_appointments.dart';
import 'package:e_hospital/screens/doctor/chats/doctor_inbox.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../widgets/drawer.dart';
import '../../../widgets/home_tile.dart';
import '../../patient/my_appointments/appointments_and_requests.dart';
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
  String? profileUrl;
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
            profileUrl = null;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _doctorName = 'Doctor';
        profileUrl = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F2F1), // Screen background
      appBar: AppBar(
        title: const Text(
          'Doctor Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF00796B),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          NotificationBell(
            userId: FirebaseAuth.instance.currentUser!.uid,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
          ),
        ],
      ),
      drawer: const PatientDrawer(),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF00796B)),
              )
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00796B).withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Welcome, $_doctorName!',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00796B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: const Color(
                              0xFF00796B,
                            ).withOpacity(0.1),
                            backgroundImage:
                                profileUrl != null
                                    ? NetworkImage(profileUrl!)
                                    : null,
                            child:
                                profileUrl == null
                                    ? const Icon(
                                      Icons.person,
                                      color: Color(0xFF00796B),
                                      size: 36,
                                    )
                                    : null,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Quick Actions Section
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00796B),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Grid View
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        childAspectRatio: 1.1,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        padding: const EdgeInsets.all(8),
                        children: [
                          _buildDashboardCard(
                            icon: Icons.calendar_today,
                            label: 'Appointments',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const DoctorAppointments(),
                                ),
                              );
                            },
                          ),
                          _buildDashboardCard(
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
                          _buildDashboardCard(
                            icon: Icons.schedule,
                            label: 'My Schedule',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ScheduleScreen(),
                                ),
                              );
                            },
                          ),
                          _buildDashboardCard(
                            icon: Icons.chat,
                            label: 'Messages',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const InboxScreen(),
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

  Widget _buildDashboardCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF00796B), Color(0xFF004D40)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
