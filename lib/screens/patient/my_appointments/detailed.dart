import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../book/book_appointment.dart';

class AppointmentDetailScreen extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const AppointmentDetailScreen({
    super.key,
    required this.docId,
    required this.data,
  });

  Future<void> _deleteAppointment(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('appointments').doc(docId).delete();
      if (context.mounted) {
        Navigator.of(context).pop(); // back to appointments list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment deleted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting appointment: $e')),
        );
      }
    }
  }
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'rejected':
        return Colors.grey;
      case 'reschedule_required':
        return Colors.deepOrange;
      case 'pending':
      default:
        return Colors.orange;
    }
  }


  @override
  Widget build(BuildContext context) {
    final timestamp = data['date'] as Timestamp;
    final date = timestamp.toDate();
    final time = data['time'] ?? '';
    final reason = data['reason'] ?? 'No reason provided';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['doctor'] ?? 'Unknown Doctor',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.deepPurple),
                        const SizedBox(width: 8),
                        Text(
                          'Status: ',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          data['status'] ?? 'pending',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(data['status']),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      data['hospital'] ?? 'Unknown Hospital',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const Divider(height: 30, thickness: 1),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.blueGrey),
                        const SizedBox(width: 8),
                        Text(
                          '${date.toLocal().toString().split(' ')[0]}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 30),
                        const Icon(Icons.access_time, color: Colors.blueGrey),
                        const SizedBox(width: 8),
                        Text(time, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Reason for Appointment:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reason,
                      style: const TextStyle(fontSize: 15, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            if ((data['status'] ?? '') == 'reschedule_required') ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.deepOrange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.warning, color: Colors.deepOrange),
                    SizedBox(width: 10),
                    Expanded(child: Text("Doctor unavailable at selected time. Please reschedule."))
                  ],
                ),
              ),
            ],
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookAppointmentScreen(
                            isRescheduling: true,
                            appointmentId: docId,
                            existingData: data,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Reschedule'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),

                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Cancel Appointment'),
                          content: const Text('Are you sure you want to cancel this appointment?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text(
                                'Yes',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _deleteAppointment(context);
                      }
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

}
