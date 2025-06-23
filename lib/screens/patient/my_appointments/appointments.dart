import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'detailed.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  Future<void> _deleteAppointment(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance.collection('appointments').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting appointment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsQuery = FirebaseFirestore.instance
        .collection('appointments')
        .orderBy('date', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: appointmentsQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.event_busy, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No appointments found.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final appointments = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              final data = appointment.data()! as Map<String, dynamic>;

              final timestamp = data['date'] as Timestamp;
              final date = timestamp.toDate();
              final time = data['time'] ?? '';

              return Dismissible(
                key: Key(appointment.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete_forever, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Cancel Appointment'),
                      content: const Text('Are you sure you want to cancel this appointment?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('No'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Yes', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) {
                  _deleteAppointment(context, appointment.id);
                },
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AppointmentDetailScreen(
                            docId: appointment.id,
                            data: data,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['doctor'] ?? 'Unknown Doctor',
                                  style: const TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data['hospital'] ?? 'Unknown Hospital',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        size: 16, color: Colors.blueAccent),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${date.toLocal().toString().split(' ')[0]}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(width: 20),
                                    const Icon(Icons.access_time,
                                        size: 16, color: Colors.blueAccent),
                                    const SizedBox(width: 6),
                                    Text(
                                      time,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}