import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  void _editAppointment(BuildContext context) {
    // TODO: Navigate to edit screen or implement edit functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit feature not implemented yet')),
    );
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['doctor'] ?? 'Unknown Doctor',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              data['hospital'] ?? 'Unknown Hospital',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.blueAccent),
                    const SizedBox(width: 8),
                    Text(
                      '${date.toLocal().toString().split(' ')[0]}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),

                const SizedBox(width: 32),
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.blueAccent),
                    const SizedBox(width: 8),
                    Text(time, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Reason:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              reason,
              style: const TextStyle(fontSize: 16),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _editAppointment(context),
                  icon: const Icon(Icons.edit),
                  label: const Text('Reschedule'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Appointment'),
                        content: const Text('Are you sure you want to delete this appointment?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
