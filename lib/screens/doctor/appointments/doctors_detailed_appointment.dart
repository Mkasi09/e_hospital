import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorAppointmentDetailScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const DoctorAppointmentDetailScreen({
    super.key,
    required this.docId,
    required this.data,
  });

  @override
  State<DoctorAppointmentDetailScreen> createState() => _DoctorAppointmentDetailScreenState();
}

class _DoctorAppointmentDetailScreenState extends State<DoctorAppointmentDetailScreen> {
  late String selectedStatus;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.data['status'] ?? 'pending';
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

  void _showStatusBottomSheet(BuildContext context) {
    final statuses = [
      'confirmed',
      'cancelled',
      'reschedule_required',
      'rejected',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Select New Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...statuses.map((status) {
              return ListTile(
                leading: Icon(Icons.circle, color: _getStatusColor(status), size: 12),
                title: Text(status),
                onTap: () async {
                  Navigator.of(context).pop(); // Close the bottom sheet
                  await _updateStatus(status);
                },
              );
            }).toList(),
          ],
        );
      },
    );
  }


  Future<void> _updateStatus(String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.docId)
          .update({'status': status});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to "$status"')),
        );
        setState(() {
          selectedStatus = status;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = widget.data['date'] as Timestamp;
    final date = timestamp.toDate();
    final time = widget.data['time'] ?? '';
    final reason = widget.data['reason'] ?? 'No reason provided';

    return Scaffold(
        appBar: AppBar(
          title: const Text('Appointment Details'),

          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'update_status') {
                  _showStatusBottomSheet(context);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'update_status',
                  child: Text('Update Status'),
                ),
              ],
            ),
          ],
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
                      widget.data['patientName'] ?? 'Unknown Patient',
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
                        const Text(
                          'Status: ',
                          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                        ),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _getStatusColor(selectedStatus),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          selectedStatus,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(selectedStatus),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.data['hospital'] ?? 'Unknown Hospital',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
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
          ],
        ),
      ),
    );
  }
}
