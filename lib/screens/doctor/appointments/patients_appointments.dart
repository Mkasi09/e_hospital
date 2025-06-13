import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../firebase_auth/user_id.dart';
import 'doctors_detailed_appointment.dart';

class DoctorAppointments extends StatelessWidget {
  const DoctorAppointments({super.key});

  Future<String?> _getDoctorName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()?['name'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Appointments'),
        centerTitle: true,
      ),
        body: FutureBuilder<String?>(
            future: _getDoctorName(),
            builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
    return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
    }

    if (!snapshot.hasData || snapshot.data == null) {
    return const Center(child: Text('Unable to load doctor information.'));
    }

    final doctorName = snapshot.data!;

    return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('appointments')
        .where('doctor', isEqualTo: doctorName)
        .orderBy('createdAt', descending: true)
        .snapshots(),
    builder: (context, snap) {
    if (snap.connectionState == ConnectionState.waiting) {
    return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
    }

    if (!snap.hasData || snap.data!.docs.isEmpty) {
    return const Center(
    child: Text(
    'No appointments found.',
    style: TextStyle(color: Colors.blueAccent, fontSize: 18),
    ),
    );
    }

    final appointments = snap.data!.docs;


    return ListView.builder(
    itemCount: appointments.length,
    itemBuilder: (context, index) {
    final appointment = appointments[index];
    final data = appointment.data() as Map<String, dynamic>;

    final patientName = data['patientName'] ?? 'Unknown';
    final status = data['status'] ?? 'Unknown';
    final time = data['time'] ?? 'N/A';
    final date = data['date']?.toDate();
    final uid = CurrentUser.uid;

    return Card(
    color: Colors.white,
    elevation: 4,
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side:
    BorderSide(color: Colors.blueAccent.shade100, width: 1),
    ),
    margin:
    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: ListTile(
    onTap: () {
    Navigator.push(
    context,
    MaterialPageRoute(
    builder: (context) => DoctorAppointmentDetailScreen(
    docId: appointment.id,
    data: data,
    ),
    ),
    );
    },
    leading: CircleAvatar(
    backgroundColor: Colors.blueAccent,
    child:
    const Icon(Icons.calendar_today, color: Colors.white),
    ),
    title: Row(
    children: [
    Expanded(
    child: Text(
    'Patient: $patientName',
    style: const TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.black,
    ),
    ),
    ),
    Container(
    width: 10,
    height: 10,
    margin: const EdgeInsets.only(left: 6),
    decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: _getStatusColor(status),
    ),
    ),
    ],
    ),
    subtitle: Row(
    children: [
    const Icon(Icons.calendar_today,
    size: 16, color: Colors.blueAccent),
    const SizedBox(width: 6),
    Text(
    date != null ? _formatDate(date) : 'N/A',
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
    trailing: const Icon(Icons.arrow_forward_ios,
    color: Colors.blueAccent),
    ),
    );
    },
    );
    },
    );
    }));
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

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.year}";
  }
}
