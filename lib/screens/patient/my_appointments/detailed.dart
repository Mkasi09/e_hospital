import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../book/book_appointment.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const AppointmentDetailScreen({
    super.key,
    required this.docId,
    required this.data,
  });

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  Map<String, dynamic>? _hospitalData;
  bool _isLoadingHospital = true;

  @override
  void initState() {
    super.initState();
    _fetchHospitalData();
  }

  Future<void> _fetchHospitalData() async {
    try {
      final hospitalName = widget.data['hospital'];
      if (hospitalName != null) {
        final querySnapshot =
            await FirebaseFirestore.instance
                .collection('hospitals')
                .where('name', isEqualTo: hospitalName)
                .limit(1)
                .get();

        if (querySnapshot.docs.isNotEmpty) {
          setState(() {
            _hospitalData = querySnapshot.docs.first.data();
          });
        }
      }
    } catch (e) {
      print('Error fetching hospital data: $e');
    } finally {
      setState(() {
        _isLoadingHospital = false;
      });
    }
  }

  Future<void> _deleteAppointment(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.docId)
          .delete();
      if (context.mounted) {
        Navigator.of(context).pop(); // back to appointments list
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Appointment deleted')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting appointment: $e')),
        );
      }
    }
  }

  Future<void> _updateStatus(String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.docId)
          .update({'status': status});

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Status updated to "$status"')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
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

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'rejected':
        return Icons.block;
      case 'reschedule_required':
        return Icons.schedule;
      case 'pending':
      default:
        return Icons.pending;
    }
  }

  String _formatAppointmentDuration() {
    final duration = widget.data['duration'] ?? 30;
    return '$duration minutes';
  }

  String _getAppointmentType() {
    return widget.data['appointmentType'] ?? 'General Consultation';
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blueGrey, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchMaps(String address) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _launchDirections(String address) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(address)}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget _buildLocationCard() {
    final hospitalLocation =
        _hospitalData?['location'] ?? 'Location not available';
    final hospitalName = widget.data['hospital'] ?? 'Unknown Hospital';

    // Use hospital location or fallback to hospital name for address
    final hospitalAddress = _hospitalData?['address'] ?? hospitalLocation;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hospital Location',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Hospital Name
            _buildInfoRow(Icons.local_hospital, 'Hospital', hospitalName),

            // Hospital Location
            _buildInfoRow(Icons.location_on, 'Address', hospitalLocation),

            // Hospital Type
            if (_hospitalData?['type'] != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.category,
                'Hospital Type',
                _hospitalData!['type'],
              ),
            ],

            const SizedBox(height: 16),

            // Map Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _launchMaps(hospitalLocation),
                    icon: const Icon(Icons.map, size: 18),
                    label: const Text('View on Map'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _launchDirections(hospitalLocation),
                    icon: const Icon(Icons.directions, size: 18),
                    label: const Text('Get Directions'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            // Contact Information from Hospital Data
            if (_hospitalData?['contactNumber'] != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.phone,
                'Contact Number',
                _hospitalData!['contactNumber'],
              ),
            ],

            if (_hospitalData?['email'] != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.email, 'Email', _hospitalData!['email']),
            ],

            if (_hospitalData?['emergencyNumber'] != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.emergency,
                'Emergency Contact',
                _hospitalData!['emergencyNumber'],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransportationInfo() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Getting There',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Parking Information from Hospital Data
            if (_hospitalData?['parkingInfo'] != null) ...[
              _buildInfoRow(
                Icons.local_parking,
                'Parking',
                _hospitalData!['parkingInfo'],
              ),
            ],

            // Public Transport from Hospital Data
            if (_hospitalData?['publicTransport'] != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.directions_bus,
                'Public Transport',
                _hospitalData!['publicTransport'],
              ),
            ],

            // Visiting Hours from Hospital Data
            if (_hospitalData?['visitingHours'] != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.access_time,
                'Visiting Hours',
                _hospitalData!['visitingHours'],
              ),
            ],

            // Default transportation tips
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tips for Your Visit:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text('• Arrive 15-20 minutes early for registration'),
                  Text('• Bring your ID and medical aid/insurance card'),
                  Text('• Carry any relevant medical records or referrals'),
                  Text('• Park in designated visitor parking areas'),
                  Text('• Check in at the reception upon arrival'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHospitalLoading() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Loading hospital information...'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = widget.data['date'] as Timestamp;
    final date = timestamp.toDate();
    final time = widget.data['time'] ?? '';
    final reason = widget.data['reason'] ?? 'No reason provided';
    final formattedDate = DateFormat('EEE, MMM d, yyyy').format(date);
    final formattedTime = DateFormat('h:mm a').format(date);
    final createdAt = widget.data['createdAt'] as Timestamp?;
    final updatedAt = widget.data['updatedAt'] as Timestamp?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _updateStatus(value),
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'pending',
                    child: Text('Mark as Pending'),
                  ),
                  const PopupMenuItem(
                    value: 'confirmed',
                    child: Text('Mark as Confirmed'),
                  ),
                  const PopupMenuItem(
                    value: 'cancelled',
                    child: Text('Mark as Cancelled'),
                  ),
                  const PopupMenuItem(
                    value: 'reschedule_required',
                    child: Text('Require Reschedule'),
                  ),
                ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(widget.data['status']),
                      color: _getStatusColor(widget.data['status']),
                      size: 40,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Appointment Status',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            widget.data['status']?.toString().toUpperCase() ??
                                'PENDING',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(widget.data['status']),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Doctor & Hospital Info
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Appointment Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.person,
                      'Doctor',
                      widget.data['doctor'] ?? 'Unknown Doctor',
                    ),
                    _buildInfoRow(
                      Icons.local_hospital,
                      'Hospital',
                      widget.data['hospital'] ?? 'Unknown Hospital',
                    ),
                    _buildInfoRow(
                      Icons.medical_services,
                      'Specialty',
                      widget.data['specialty'] ?? 'General Medicine',
                    ),
                    _buildInfoRow(
                      Icons.category,
                      'Appointment Type',
                      _getAppointmentType(),
                    ),
                    _buildInfoRow(
                      Icons.timer,
                      'Duration',
                      _formatAppointmentDuration(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Location Information
            if (_isLoadingHospital)
              _buildHospitalLoading()
            else
              _buildLocationCard(),

            const SizedBox(height: 20),

            // Transportation Information
            if (!_isLoadingHospital && _hospitalData != null)
              _buildTransportationInfo(),

            const SizedBox(height: 20),

            // Date & Time Information
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Schedule',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(Icons.calendar_today, 'Date', formattedDate),
                    _buildInfoRow(
                      Icons.access_time,
                      'Time',
                      '$time ($formattedTime)',
                    ),
                    if (createdAt != null)
                      _buildInfoRow(
                        Icons.create,
                        'Created',
                        DateFormat(
                          'MMM d, yyyy - h:mm a',
                        ).format(createdAt.toDate()),
                      ),
                    if (updatedAt != null)
                      _buildInfoRow(
                        Icons.update,
                        'Last Updated',
                        DateFormat(
                          'MMM d, yyyy - h:mm a',
                        ).format(updatedAt.toDate()),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Reason for Appointment
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reason for Appointment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        reason,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Additional Notes
            if (widget.data['notes'] != null &&
                widget.data['notes'].toString().isNotEmpty)
              Column(
                children: [
                  const SizedBox(height: 20),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Additional Notes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[100]!),
                            ),
                            child: Text(
                              widget.data['notes'].toString(),
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

            // Reschedule Required Warning
            if ((widget.data['status'] ?? '') == 'reschedule_required') ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepOrange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepOrange[100]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.deepOrange[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reschedule Required',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.data['rescheduleReason'] ??
                                'Doctor unavailable at selected time. Please reschedule.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.deepOrange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => BookAppointmentScreen(
                                isRescheduling: true,
                                appointmentId: widget.docId,
                                existingData: widget.data,
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Cancel Appointment'),
                              content: const Text(
                                'Are you sure you want to cancel this appointment?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(false),
                                  child: const Text('No'),
                                ),
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(true),
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
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
