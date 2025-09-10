import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ServiceRequestsTab extends StatelessWidget {
  const ServiceRequestsTab({super.key});

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'scheduled':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    final serviceRequestsQuery = FirebaseFirestore.instance
        .collection('service_requests')
        .where('patientId', isEqualTo: userId)
        .orderBy('timestamp', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: serviceRequestsQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No service requests found.'));
        }

        final requests = snapshot.data!.docs;

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index].data() as Map<String, dynamic>;

            final scheduledDateStr = request['scheduledDate'] as String?;
            String formattedScheduledDate = 'Date not set';
            if (scheduledDateStr != null) {
              try {
                final date = DateTime.parse(scheduledDateStr);
                formattedScheduledDate = DateFormat.yMMMd().format(date);
              } catch (_) {}
            }

            final status = request['status'] ?? 'Unknown';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request['serviceName'] ?? 'Unknown Service',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Ordered by Dr Sfiso',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          Text(
                            'Result: ${request['result'] ?? 'Pending'}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formattedScheduledDate,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (request['price'] != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'R${request['price']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
