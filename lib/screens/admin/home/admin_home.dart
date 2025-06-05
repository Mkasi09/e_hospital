import 'package:e_hospital/widgets/drawer.dart';
import 'package:flutter/material.dart';

import 'doctors/doctors.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      drawer: PatientDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          children: [
            _buildCard(
              context,
              title: 'Doctors',
              icon: Icons.medical_services,
              color: Colors.teal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DoctorsScreen()),
                );
              },
            ),
            _buildCard(
              context,
              title: 'Patients',
              icon: Icons.people,
              color: Colors.blue,
              onTap: () {
                Navigator.pushNamed(context, '/managePatients');
              },
            ),
            _buildCard(
              context,
              title: 'Appointments',
              icon: Icons.calendar_today,
              color: Colors.deepPurple,
              onTap: () {
                Navigator.pushNamed(context, '/appointments');
              },
            ),
            _buildCard(
              context,
              title: 'Reports',
              icon: Icons.insert_chart,
              color: Colors.orange,
              onTap: () {
                Navigator.pushNamed(context, '/reports');
              },
            ),
            _buildCard(
              context,
              title: 'Settings',
              icon: Icons.settings,
              color: Colors.grey,
              onTap: () {
                Navigator.pushNamed(context, '/adminSettings');
              },
            ),
            _buildCard(
              context,
              title: 'Logout',
              icon: Icons.logout,
              color: Colors.red,
              onTap: () {
                // Add your logout logic
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context,
      {required String title,
        required IconData icon,
        required Color color,
        required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        color: color.withOpacity(0.8),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 50, color: Colors.white),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
