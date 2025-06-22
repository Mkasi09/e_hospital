import 'package:e_hospital/screens/patient/chat/chats.dart';
import 'package:e_hospital/screens/patient/my_appointments/appointments.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../doctor/doctors_notifications/doctors_notification_screen.dart';
import '../book/book_appointment.dart';
import '../files/files_and_prescriptions.dart';
import '../../../widgets/drawer.dart';
import '../../../widgets/home_tile.dart';


class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key});

  void _launchPhone(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>  NotificationScreen(userId: FirebaseAuth.instance.currentUser!.uid)),
              );
            },
          ),
        ],
      ),
      drawer: const PatientDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome back!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('What would you like to do today?'),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  DashboardCard(
                    icon: Icons.calendar_today,
                    label: 'Book Appointment',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BookAppointmentScreen()),
                      );
                    },

                  ),
                  DashboardCard(
                    icon: Icons.edit_calendar,
                    label: 'My Appointments',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AppointmentsScreen()),
                      );},
                  ),
                  DashboardCard(
                    icon: Icons.folder_shared,
                    label: 'Files & Prescriptions',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const FilesAndPrescriptionsScreen()),
                      );},
                  ),
                  DashboardCard(
                    icon: Icons.chat,
                    label: 'Chat with Doctor',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ChatsScreen()),
                      );},
                  ),
                  DashboardCard(
                    icon: Icons.local_hospital,
                    label: 'Emergency & Help',
                    onTap: () {
                      _launchPhone('123');
                    },
                  ),
                  DashboardCard(
                    icon: Icons.payment,
                    label: 'Billing & Payment',
                    onTap: () {},
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
