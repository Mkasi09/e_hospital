import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Implement filter functionality
              _showFilterBottomSheet(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Implement more options
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildDateHeader('Today'),
          _buildNotificationItem(
            icon: Icons.calendar_today,
            iconColor: Colors.blue,
            title: 'New Appointment Scheduled',
            subtitle: 'Dr. Smith - Cardiology, 10:30 AM',
            time: '2 hours ago',
            isUnread: true,
          ),
          _buildNotificationItem(
            icon: Icons.message,
            iconColor: Colors.green,
            title: 'New Message from Patient',
            subtitle: 'John Doe: "I have a question about my prescription"',
            time: '3 hours ago',
            isUnread: true,
          ),
          _buildNotificationItem(
            icon: Icons.person_add,
            iconColor: Colors.purple,
            title: 'New Patient Registered',
            subtitle: 'Sarah Johnson - Registered for annual checkup',
            time: '5 hours ago',
            isUnread: false,
          ),
          _buildDateHeader('Yesterday'),
          _buildNotificationItem(
            icon: Icons.schedule,
            iconColor: Colors.orange,
            title: 'Schedule Change',
            subtitle: 'Your Wednesday shift has been extended by 1 hour',
            time: 'Yesterday, 4:30 PM',
            isUnread: false,
          ),
          _buildNotificationItem(
            icon: Icons.calendar_today,
            iconColor: Colors.blue,
            title: 'Appointment Reminder',
            subtitle: 'Mrs. Anderson - Pediatrics, 9:00 AM tomorrow',
            time: 'Yesterday, 2:15 PM',
            isUnread: false,
          ),
          _buildNotificationItem(
            icon: Icons.medical_services,
            iconColor: Colors.red,
            title: 'Lab Results Available',
            subtitle: 'Blood test results for patient Michael Brown',
            time: 'Yesterday, 11:20 AM',
            isUnread: false,
          ),
          _buildDateHeader('This Week'),
          _buildNotificationItem(
            icon: Icons.event_busy,
            iconColor: Colors.amber,
            title: 'Appointment Cancelled',
            subtitle: 'Robert Wilson cancelled his 3:00 PM appointment',
            time: 'Monday, 1:45 PM',
            isUnread: false,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Mark all as read functionality
        },
        child: const Icon(Icons.done_all),
        tooltip: 'Mark all as read',
      ),
    );
  }

  Widget _buildDateHeader(String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        date,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
    required bool isUnread,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      elevation: isUnread ? 2.0 : 0.5,
      color: isUnread ? Colors.blue.shade50 : Colors.white,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            const SizedBox(height: 4),
            Text(
              time,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: isUnread
            ? const CircleAvatar(
          radius: 4,
          backgroundColor: Colors.blue,
        )
            : null,
        onTap: () {
          // Handle notification tap
        },
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Notifications',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildFilterOption('All Notifications', true),
              _buildFilterOption('Appointments', false),
              _buildFilterOption('Messages', false),
              _buildFilterOption('Patients', false),
              _buildFilterOption('Schedule', false),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String title, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            onChanged: (value) {},
          ),
          Text(title),
        ],
      ),
    );
  }
}