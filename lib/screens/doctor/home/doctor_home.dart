import 'package:e_hospital/screens/doctor/appointments/patients_appointments.dart';
import 'package:e_hospital/screens/doctor/chats/doctor_inbox.dart';
import 'package:flutter/material.dart';

import '../../../widgets/drawer.dart';
import '../../../widgets/home_tile.dart';
import '../../patient/my_appointments/appointments.dart';
import '../doctors_notifications/doctors_notification_screen.dart';
import '../patients/Doctors_patient_screen.dart';
import '../schedule/schedule_screen.dart';

class DoctorsHomepage extends StatelessWidget {
  final String doctorName;

  const DoctorsHomepage({super.key, this.doctorName = 'Dr. Smith'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationScreen()),
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
              'Welcome, $doctorName!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/images/doctor_avatar.png'), // Make sure this exists or use NetworkImage
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
                        MaterialPageRoute(builder: (context) => const DoctorAppointments()),
                      );
                    },
                  ),
                  DashboardCard(
                    icon: Icons.people,
                    label: 'Patients',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PatientsScreen()),
                        );
                      },
                  ),
                  DashboardCard(
                    icon: Icons.schedule,
                    label: 'Schedule',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScheduleScreen(), // assuming no arguments needed
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
                          builder: (context) => const InboxScreen(), // assuming no arguments needed
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
