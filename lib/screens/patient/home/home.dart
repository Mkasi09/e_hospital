import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_hospital/screens/patient/chat/chats.dart';
import 'package:e_hospital/screens/patient/chat/inbox.dart';
import 'package:e_hospital/screens/patient/emergency/emergeny_help.dart';
import 'package:e_hospital/screens/patient/my_appointments/appointments_and_requests.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../doctor/doctors_notifications/doctors_notification_screen.dart';
import '../ai/ai_chatbot.dart';
import '../book/book_appointment.dart';
import '../files/files_and_prescriptions.dart';
import '../../../widgets/drawer.dart';
import '../../../widgets/home_tile.dart';
import '../payments/billing_payment.dart';
import 'ai_icon.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  Map<String, dynamic>? nextAppointment;

  @override
  void initState() {
    super.initState();
    fetchNextAppointment();
  }

  Future<void> fetchNextAppointment() async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final now = DateTime.now();

      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('appointments')
              .where('userId', isEqualTo: userId)
              .where('status', isEqualTo: 'pending')
              .orderBy('date')
              .get();

      // Filter out appointments that have already passed
      final upcoming =
          querySnapshot.docs.where((doc) {
            final data = doc.data();
            final Timestamp dateStamp = data['date'];
            final DateTime date = dateStamp.toDate();

            // Parse time if stored as 'HH:mm' string
            final String timeStr = data['time'];
            final timeParts = timeStr.split(':');
            final appointmentDateTime = DateTime(
              date.year,
              date.month,
              date.day,
              int.parse(timeParts[0]),
              int.parse(timeParts[1]),
            );

            return appointmentDateTime.isAfter(now);
          }).toList();

      if (upcoming.isNotEmpty) {
        final data = upcoming.first.data();
        final Timestamp timestamp = data['date'];
        final DateTime dateTime = timestamp.toDate();
        final String formattedDate = DateFormat(
          'EEE, MMM d, yyyy',
        ).format(dateTime);
        final String formattedTime = data['time'];

        setState(() {
          nextAppointment = {
            'doctor': data['doctor'],
            'date': formattedDate,
            'time': formattedTime,
          };
        });
      } else {
        setState(() => nextAppointment = {});
      }
    } catch (e) {
      print("Error fetching next appointment: $e");
      setState(() => nextAppointment = {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('assets/icon2.png', height: 96),
            const Text(
              'e-Hospital',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
          ),
        ],
        backgroundColor: const Color(0xFF00796B),
        elevation: 4,
      ),

      drawer: const RoleBasedDrawer(),
      body: Stack(
        children: [
          Container(
            color: const Color(0xFFE0F2F1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'How are you feeling today?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00796B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB2DFDB),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child:
                              nextAppointment == null
                                  ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                  : Column(
                                    children: [
                                      const Text(
                                        'Next Appointment',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF00796B),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        nextAppointment!['date'] ??
                                            'Unknown Date',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF00796B),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${nextAppointment!['time']} - ${nextAppointment!['doctor']}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF00796B),
                                        ),
                                      ),
                                    ],
                                  ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB2DFDB),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Column(
                            children: [
                              Text(
                                'Recent Prescription',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF00796B),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Updated today',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00796B),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'View details',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF00796B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
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
                          color: Colors.teal,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const BookAppointmentScreen(),
                              ),
                            );
                          },
                        ),
                        DashboardCard(
                          icon: Icons.assignment_ind,
                          label: 'Appointments / Requests',
                          color: Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) =>
                                        const AppointmentsAndRequestsScreen(),
                              ),
                            );
                          },
                        ),
                        DashboardCard(
                          icon: Icons.folder_shared,
                          label: 'Files & Prescriptions',
                          color: Colors.green,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        const FilesAndPrescriptionsScreen(),
                              ),
                            );
                          },
                        ),
                        DashboardCard(
                          icon: Icons.chat,
                          label: 'Chat with Doctor',
                          color: Colors.indigo,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InboxScreen(),
                              ),
                            );
                          },
                        ),
                        DashboardCard(
                          icon: Icons.local_hospital,
                          label: 'Emergency & Help',
                          color: Colors.red,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const EmergencyHelpScreen(),
                              ),
                            );
                          },
                        ),
                        DashboardCard(
                          icon: Icons.payment,
                          label: 'Billing & Payment',
                          color: Colors.orange,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        const BillingAndPaymentScreen(),
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
          ),

          // 🔹 Floating Chatbot Button
          FloatingChatBotIcon(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatbotScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
