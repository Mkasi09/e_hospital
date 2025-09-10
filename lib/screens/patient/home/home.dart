import 'package:e_hospital/screens/patient/ai/ai_chatbot.dart';
import 'package:e_hospital/screens/patient/chat/chats.dart'; // Assuming your chatbot screen
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../doctor/chats/doctor_inbox.dart';
import '../../doctor/doctors_notifications/doctors_notification_screen.dart';
import '../book/book_appointment.dart';
import '../files/files_and_prescriptions.dart';
import '../../../widgets/drawer.dart';
import '../../../widgets/home_tile.dart';
import '../my_appointments/appointments.dart';
import '../payments/billing_payment.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
                MaterialPageRoute(builder: (context) => NotificationScreen()),
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
            const SizedBox(height: 60),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AppointmentsScreen()),
                      );
                    },
                  ),
                  DashboardCard(
                    icon: Icons.folder_shared,
                    label: 'Files & Prescriptions',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FilesAndPrescriptionsScreen()),
                      );
                    },
                  ),
                  DashboardCard(
                    icon: Icons.chat,
                    label: 'Chat with Doctor',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => InboxScreen()),
                      );
                    },
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BillingAndPaymentScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // 💬 AI Chatbot Button on Bottom Right
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 90),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatbotScreen()),
            );
          },
          tooltip: "Chatbot", // Shows text on hover/long press
          backgroundColor: Colors.blueAccent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.smart_toy, color: Colors.white, size: 28),
              SizedBox(height: 2),
              Text(
                "AI",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,


    );
  }
}
