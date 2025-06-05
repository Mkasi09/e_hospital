import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
                  HomeOptionTile(
                    icon: Icons.calendar_today,
                    label: 'Book Appointment',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BookAppointmentScreen()),
                      );
                    },

                  ),
                  HomeOptionTile(
                    icon: Icons.folder_shared,
                    label: 'Files & Prescriptions',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const FilesAndPrescriptionsScreen()),
                      );},
                  ),
                  HomeOptionTile(
                    icon: Icons.chat,
                    label: 'Chat with Doctor',
                    onTap: () {},
                  ),
                  HomeOptionTile(
                    icon: Icons.health_and_safety,
                    label: 'Health Tools',
                    onTap: () {},
                  ),
                  HomeOptionTile(
                    icon: Icons.local_hospital,
                    label: 'Emergency & Help',
                    onTap: () {
                      _launchPhone('123');
                    },
                  ),
                  HomeOptionTile(
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
