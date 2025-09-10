import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_hospital/screens/patient/chat/chats.dart';
import 'package:e_hospital/screens/patient/chat/inbox.dart';
import 'package:e_hospital/screens/patient/my_appointments/appointments_and_requests.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../doctor/doctors_notifications/doctors_notification_screen.dart';
import '../book/book_appointment.dart';
import '../files/files_and_prescriptions.dart';
import '../../../widgets/drawer.dart';
import '../../../widgets/home_tile.dart';
import '../payments/billing_payment.dart';

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

      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('appointments')
              .where('userId', isEqualTo: userId)
              .where('status', isEqualTo: 'pending')
              .orderBy('date') // make sure 'date' is a Timestamp in Firestore
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();

        // Convert Firestore Timestamp to DateTime
        final Timestamp timestamp = data['date'];
        final DateTime dateTime = timestamp.toDate();
        final String formattedDate =
            "${DateFormat('EEE, MMM d, yyyy').format(dateTime)}";

        final String formattedTime = "${data['time']}"; // Keep your stored time

        setState(() {
          nextAppointment = {
            'doctor': data['doctor'],
            'date': formattedDate,
            'time': formattedTime,
          };
        });
      } else {
        setState(() {
          nextAppointment = {};
        });
      }
    } catch (e) {
      print("Error fetching next appointment: $e");
      setState(() {
        nextAppointment = {};
      });
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
            Image.asset(
              'assets/icon2.png', // your logo
              height: 96,
            ),
            const Text(
              'e-Hospital',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white, // white text for contrast
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

        // 🔹 Hospital colors gradient
        backgroundColor: const Color(0xFF00796B),
        elevation: 4,
      ),

      drawer: const PatientDrawer(),
      body: Container(
        color: const Color(0xFFE0F2F1), // Light teal background
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
                              ? const Center(child: CircularProgressIndicator())
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
                                    nextAppointment!['date'] ?? 'Unknown Date',
                                    style: const TextStyle(
                                      fontSize: 16,
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
                      color: Colors.teal, // calming hospital teal
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BookAppointmentScreen(),
                          ),
                        );
                      },
                    ),
                    DashboardCard(
                      icon: Icons.assignment_ind,
                      label: 'Appointments / Requests',
                      color: Colors.blue, // professional medical blue
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => const AppointmentsAndRequestsScreen(),
                          ),
                        );
                      },
                    ),
                    DashboardCard(
                      icon: Icons.folder_shared,
                      label: 'Files & Prescriptions',
                      color: Colors.green, // pharmacy/records green
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
                      color: Colors.indigo, // trust/communication indigo
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
                      color: Colors.red, // 🔴 emergency red
                      onTap: () {},
                    ),
                    DashboardCard(
                      icon: Icons.payment,
                      label: 'Billing & Payment',
                      color: Colors.orange, // finances = orange/yellow
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => const BillingAndPaymentScreen(),
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
    );
  }
}
