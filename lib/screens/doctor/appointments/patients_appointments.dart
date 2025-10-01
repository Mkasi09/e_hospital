import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../firebase_auth/user_id.dart';
import 'doctors_detailed_appointment.dart';

class DoctorAppointments extends StatefulWidget {
  const DoctorAppointments({super.key});

  @override
  State<DoctorAppointments> createState() => _DoctorAppointmentsState();
}

class _DoctorAppointmentsState extends State<DoctorAppointments> {
  String _selectedFilter = 'all';
  final List<String> _filterOptions = [
    'all',
    'pending',
    'confirmed',
    'cancelled',
    'reschedule_required',
  ];

  Future<String?> _getDoctorName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()?['name'];
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Confirmed';
      case 'cancelled':
        return 'Cancelled';
      case 'rejected':
        return 'Rejected';
      case 'reschedule_required':
        return 'Reschedule Required';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFF00796B);
      case 'cancelled':
        return Colors.red;
      case 'rejected':
        return Colors.grey;
      case 'reschedule_required':
        return Colors.orange;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  Color _getStatusTextColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFF00796B);
      case 'cancelled':
        return Colors.red;
      case 'rejected':
        return Colors.grey;
      case 'reschedule_required':
        return Colors.orange;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }

  String _formatTime(String time) {
    if (time.toLowerCase().contains('am') ||
        time.toLowerCase().contains('pm')) {
      return time;
    }

    try {
      final timeFormat = DateFormat('HH:mm');
      final dateTime = timeFormat.parse(time);
      return DateFormat('h:mm a').format(dateTime);
    } catch (e) {
      return time;
    }
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children:
            _filterOptions.map((filter) {
              final isSelected = _selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    filter == 'all' ? 'All' : _getStatusLabel(filter),
                    style: TextStyle(
                      color:
                          isSelected ? Colors.white : const Color(0xFF00796B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  backgroundColor: Colors.white,
                  selectedColor: const Color(0xFF00796B),
                  checkmarkColor: Colors.white,
                  side: BorderSide(
                    color: const Color(0xFF00796B).withOpacity(0.3),
                    width: 1,
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildAppointmentCard(
    DocumentSnapshot appointment,
    Map<String, dynamic> data,
  ) {
    final patientName = data['patientName'] ?? 'Unknown';
    final status = data['status'] ?? 'pending';
    final time = data['time'] ?? 'N/A';
    final date = data['date']?.toDate();
    final reason = data['reason'] ?? 'No reason provided';

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: const Color(0xFF00796B).withOpacity(0.1),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => DoctorAppointmentDetailScreen(
                    docId: appointment.id,
                    data: data,
                  ),
            ),
          );
        },
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF00796B).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.calendar_today,
            color: const Color(0xFF00796B),
            size: 24,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    patientName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(status),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getStatusLabel(status),
                    style: TextStyle(
                      color: _getStatusTextColor(status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              reason,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: const Color(0xFF00796B),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    date != null ? _formatDate(date) : 'N/A',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: const Color(0xFF00796B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(time),
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ],
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: const Color(0xFF00796B),
          size: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F2F1), // Screen background
      appBar: AppBar(
        title: const Text(
          'My Appointments',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF00796B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<String?>(
        future: _getDoctorName(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00796B)),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text(
                'Unable to load doctor information.',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          }

          final doctorName = snapshot.data!;

          return Column(
            children: [
              _buildFilterChips(),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('appointments')
                          .where('doctor', isEqualTo: doctorName)
                          .snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00796B),
                        ),
                      );
                    }

                    if (!snap.hasData) {
                      return const Center(
                        child: Text(
                          'Error loading appointments.',
                          style: TextStyle(color: Colors.red, fontSize: 16),
                        ),
                      );
                    }

                    final appointments = snap.data!.docs;

                    // Filter appointments based on selected filter
                    final filteredAppointments =
                        _selectedFilter == 'all'
                            ? appointments
                            : appointments.where((appointment) {
                              final data =
                                  appointment.data() as Map<String, dynamic>;
                              final status = data['status'] ?? 'pending';
                              return status == _selectedFilter;
                            }).toList();

                    if (filteredAppointments.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 64,
                              color: const Color(0xFF00796B).withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedFilter == 'all'
                                  ? 'No appointments found'
                                  : 'No ${_getStatusLabel(_selectedFilter).toLowerCase()} appointments',
                              style: const TextStyle(
                                color: Color(0xFF00796B),
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedFilter == 'all'
                                  ? 'You don\'t have any appointments yet'
                                  : 'You don\'t have any ${_getStatusLabel(_selectedFilter).toLowerCase()} appointments',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredAppointments.length,
                      itemBuilder: (context, index) {
                        final appointment = filteredAppointments[index];
                        final data = appointment.data() as Map<String, dynamic>;
                        return _buildAppointmentCard(appointment, data);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
