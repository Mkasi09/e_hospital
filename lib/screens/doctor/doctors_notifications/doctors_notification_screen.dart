import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../appointments/doctors_detailed_appointment.dart'; // Add this at the top

class NotificationScreen extends StatefulWidget {


  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String selectedFilter = 'all'; // 'all', 'doctor_appointment', etc.
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            //.orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          // Filter by type if selected
          final notifications = docs.where((doc) {
            if (selectedFilter == 'all') return true;
            return doc['type'] == selectedFilter;
          }).toList();

          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications found.'));
          }

          // Group notifications by date headers
          List<Widget> grouped = [];
          String? lastDateGroup;

          for (var doc in notifications) {
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = (data['timestamp'] as Timestamp).toDate();
            final dateGroup = _getDateGroup(timestamp);

            if (dateGroup != lastDateGroup) {
              grouped.add(_buildDateHeader(dateGroup));
              lastDateGroup = dateGroup;
            }
            grouped.add(_buildNotificationItem(
              id: doc.id,
              title: data['title'],
              subtitle: data['body'],
              timestamp: timestamp,
              isUnread: !(data['isRead'] ?? false),
              icon: Icons.notifications,
              fullData: data, // ✅ This is required
            ));

          }

          return ListView(children: grouped);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _markAllAsRead,
        child: const Icon(Icons.done_all),
        tooltip: 'Mark all as read',
      ),
    );
  }

  String _getDateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) return 'Today';
    if (dateToCheck == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('EEEE, MMM d').format(date);
  }

  Widget _buildDateHeader(String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        date,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _buildNotificationItem({
    required String id,
    required String title,
    required String subtitle,
    required DateTime timestamp,
    required bool isUnread,
    required IconData icon,
    required Map<String, dynamic> fullData,
  }) {
    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        await FirebaseFirestore.instance.collection('notifications').doc(id).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted')),
        );
      },
      child: Card(
        color: isUnread ? Colors.blue.shade50 : Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Icon(icon, color: Colors.blue),
          ),
          title: Text(title, style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.normal)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subtitle),
              const SizedBox(height: 4),
              Text(
                DateFormat('MMM d, yyyy – HH:mm').format(timestamp),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'mark_unread') {
                await FirebaseFirestore.instance
                    .collection('notifications')
                    .doc(id)
                    .update({'isRead': false});
              }
            },
            itemBuilder: (context) => [
              if (!isUnread)
                const PopupMenuItem<String>(
                  value: 'mark_unread',
                  child: Text('Mark as unread'),
                ),
            ],
          ),
            onTap: () async {
              await _markAsRead(id);

              final appointmentId = fullData['appointmentId'] ?? fullData['additionalData']?['appointmentId'];

              if (appointmentId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No appointment ID found in notification')),
                );
                return;
              }

              final appointmentDoc = await FirebaseFirestore.instance
                  .collection('appointments')
                  .doc(appointmentId)
                  .get();

              if (appointmentDoc.exists) {
                final appointmentData = appointmentDoc.data()!;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DoctorAppointmentDetailScreen(
                      docId: appointmentId,
                      data: appointmentData,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Appointment not found')),
                );
              }
            }




        ),
      ),
    );
  }




  Future<void> _markAsRead(String docId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(docId)
        .update({'isRead': true});
  }


  void _markAllAsRead() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('All Notifications'),
            onTap: () => _setFilter('all'),
          ),
          ListTile(
            title: const Text('Doctor Appointments'),
            onTap: () => _setFilter('doctor_appointment'),
          ),
          ListTile(
            title: const Text('Messages'),
            onTap: () => _setFilter('message'),
          ),
          ListTile(
            title: const Text('Patients'),
            onTap: () => _setFilter('patient'),
          ),
        ],
      ),
    );
  }

  void _setFilter(String filter) {
    Navigator.pop(context);
    setState(() {
      selectedFilter = filter;
    });
  }
}
