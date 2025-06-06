import 'package:flutter/material.dart';

import '../../../widgets/drawer.dart';
import '../../../widgets/home_tile.dart';

class DoctorsHomepage extends StatelessWidget {
  final String doctorName;

  const DoctorsHomepage({super.key, this.doctorName = 'Dr. Smith'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
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
                      // Navigate to appointments screen
                    },
                  ),
                  DashboardCard(
                    icon: Icons.people,
                    label: 'Patients',
                    onTap: () {
                      // Navigate to patients screen
                    },
                  ),
                  DashboardCard(
                    icon: Icons.schedule,
                    label: 'Schedule',
                    onTap: () {
                      // Navigate to schedule screen
                    },
                  ),
                  DashboardCard(
                    icon: Icons.chat,
                    label: 'Messages',
                    onTap: () {
                      // Navigate to messages screen
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
