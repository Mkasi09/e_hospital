import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../patients/doctors_patient_history_screen.dart';

class DoctorAppointmentDetailScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const DoctorAppointmentDetailScreen({
    super.key,
    required this.docId,
    required this.data,
  });

  @override
  State<DoctorAppointmentDetailScreen> createState() =>
      _DoctorAppointmentDetailScreenState();
}

class _DoctorAppointmentDetailScreenState
    extends State<DoctorAppointmentDetailScreen> {
  late String selectedStatus;
  bool _isUpdating = false;
  String? _calculatedAge;
  String? _calculatedGender;
  Map<String, dynamic>? _patientData;
  bool _isLoadingPatient = false;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.data['status'] ?? 'pending';
    _fetchPatientData();
  }

  Future<void> _fetchPatientData() async {
    final userId = widget.data['userId'];
    if (userId == null || userId.toString().isEmpty) {
      _calculateDemographicsFromAppointmentData();
      return;
    }

    setState(() {
      _isLoadingPatient = true;
    });

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId.toString())
              .get();

      if (doc.exists) {
        setState(() {
          _patientData = doc.data();
        });
        _calculateDemographicsFromPatientData();
      } else {
        _calculateDemographicsFromAppointmentData();
      }
    } catch (e) {
      print('Error fetching patient data: $e');
      _calculateDemographicsFromAppointmentData();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPatient = false;
        });
      }
    }
  }

  void _calculateDemographicsFromPatientData() {
    if (_patientData != null) {
      final idNumber = _patientData!['id']?.toString() ?? '';
      _calculateDemographics(idNumber);
    } else {
      _calculateDemographicsFromAppointmentData();
    }
  }

  void _calculateDemographicsFromAppointmentData() {
    final idNumber =
        widget.data['patientId']?.toString() ??
        widget.data['id']?.toString() ??
        '';
    _calculateDemographics(idNumber);
  }

  void _calculateDemographics(String idNumber) {
    if (idNumber.isNotEmpty) {
      _calculatedAge = _calculateAgeFromId(idNumber);
      _calculatedGender = _determineGenderFromId(idNumber);
    } else {
      _calculatedAge = 'N/A';
      _calculatedGender = 'N/A';
    }
  }

  String _calculateAgeFromId(String idNumber) {
    try {
      // South African ID format: YYMMDDSSSSCAZ
      // YYMMDD = birth date
      if (idNumber.length < 6) return 'N/A';

      final yearPrefix = idNumber.substring(0, 2);
      final month = idNumber.substring(2, 4);
      final day = idNumber.substring(4, 6);

      // Validate date components
      if (int.parse(month) > 12 || int.parse(month) < 1) return 'N/A';
      if (int.parse(day) > 31 || int.parse(day) < 1) return 'N/A';

      // Determine century based on current year
      final now = DateTime.now();
      final currentYear = now.year;
      final shortYear = int.parse(yearPrefix);

      int century;
      if (shortYear <= (currentYear % 100)) {
        century = (currentYear ~/ 100) * 100;
      } else {
        century = ((currentYear ~/ 100) - 1) * 100;
      }

      final birthYear = century + shortYear;
      final birthDate = DateTime(birthYear, int.parse(month), int.parse(day));

      // Check if birth date is valid and not in future
      if (birthDate.isAfter(now)) {
        return 'N/A';
      }

      final age = now.difference(birthDate).inDays ~/ 365;
      return '$age Years Old';
    } catch (e) {
      return 'N/A';
    }
  }

  String _determineGenderFromId(String idNumber) {
    try {
      // South African ID format: YYMMDDSSSSCAZ
      // The 10th digit (0-9) determines gender
      // 0-4 = Female, 5-9 = Male
      if (idNumber.length < 10) return 'N/A';

      final genderDigit = int.parse(idNumber.substring(9, 10));
      return genderDigit < 5 ? 'Female' : 'Male';
    } catch (e) {
      return 'N/A';
    }
  }

  String get _patientName {
    if (_patientData != null && _patientData!['fullName'] != null) {
      return _patientData!['fullName'];
    }
    return widget.data['patientName'] ?? 'Unknown Patient';
  }

  String get _patientEmail {
    if (_patientData != null && _patientData!['email'] != null) {
      return _patientData!['email'];
    }
    return widget.data['patientEmail'] ?? 'N/A';
  }

  String get _patientIdNumber {
    if (_patientData != null && _patientData!['id'] != null) {
      return _patientData!['id'];
    }
    return widget.data['patientId']?.toString() ??
        widget.data['id']?.toString() ??
        'N/A';
  }

  String get _patientContact {
    if (_patientData != null && _patientData!['contact'] != null) {
      return _patientData!['contact'];
    }
    if (_patientData != null && _patientData!['phone'] != null) {
      return _patientData!['phone'];
    }
    return widget.data['patientContact'] ?? 'N/A';
  }

  // Enhanced status management
  static const Map<String, Map<String, dynamic>> statusConfig = {
    'confirmed': {
      'color': Colors.green,
      'icon': Icons.check_circle,
      'label': 'Confirmed',
    },
    'cancelled': {
      'color': Colors.red,
      'icon': Icons.cancel,
      'label': 'Cancelled',
    },
    'rejected': {
      'color': Colors.grey,
      'icon': Icons.block,
      'label': 'Rejected',
    },
    'reschedule_required': {
      'color': Colors.deepOrange,
      'icon': Icons.schedule,
      'label': 'Reschedule Required',
    },
    'pending': {
      'color': Colors.orange,
      'icon': Icons.pending,
      'label': 'Pending',
    },
  };

  Color _getStatusColor(String status) {
    return statusConfig[status.toLowerCase()]?['color'] ?? Colors.orange;
  }

  IconData _getStatusIcon(String status) {
    return statusConfig[status.toLowerCase()]?['icon'] ?? Icons.pending;
  }

  String _getStatusLabel(String status) {
    return statusConfig[status.toLowerCase()]?['label'] ?? 'Pending';
  }

  void _showStatusBottomSheet(BuildContext context) {
    final availableStatuses = [
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
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Update Appointment Status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...availableStatuses.map((status) {
                final isCurrentStatus = status == selectedStatus;
                return ListTile(
                  leading: Icon(
                    _getStatusIcon(status),
                    color: _getStatusColor(status),
                    size: 24,
                  ),
                  title: Text(
                    _getStatusLabel(status),
                    style: TextStyle(
                      fontWeight:
                          isCurrentStatus ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing:
                      isCurrentStatus
                          ? const Icon(Icons.check, color: Colors.blue)
                          : null,
                  onTap: () async {
                    Navigator.of(context).pop();
                    if (!isCurrentStatus) {
                      await _updateStatus(status);
                    }
                  },
                );
              }).toList(),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateStatus(String status) async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.docId)
          .update({
            'status': status,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to "${_getStatusLabel(status)}"'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          selectedStatus = status;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Widget _buildInfoRow(
    IconData icon,
    String title,
    String value, {
    bool isImportant = false,
  }) {
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
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isImportant ? FontWeight.bold : FontWeight.w600,
                    color: isImportant ? Colors.blueGrey : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = widget.data['date'] as Timestamp?;
    final date = timestamp?.toDate();
    final time = widget.data['time'] ?? 'Not specified';
    final reason = widget.data['reason'] ?? 'No reason provided';
    final createdAt = widget.data['createdAt'] as Timestamp?;
    final updatedAt = widget.data['updatedAt'] as Timestamp?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        actions: [
          if (!_isUpdating && !_isLoadingPatient)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'update_status') {
                  _showStatusBottomSheet(context);
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'update_status',
                      child: Row(
                        children: [
                          Icon(Icons.update, size: 20),
                          SizedBox(width: 8),
                          Text('Update Status'),
                        ],
                      ),
                    ),
                  ],
            ),
        ],
      ),
      body:
          _isUpdating || _isLoadingPatient
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
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
                              _getStatusIcon(selectedStatus),
                              color: _getStatusColor(selectedStatus),
                              size: 40,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Appointment Status",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  Text(
                                    _getStatusLabel(selectedStatus),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _getStatusColor(selectedStatus),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showStatusBottomSheet(context),
                              tooltip: 'Update Status',
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Patient Information
                    _buildSectionCard("Patient Information", [
                      _buildInfoRow(
                        Icons.person,
                        "Name",
                        _patientName,
                        isImportant: true,
                      ),
                      _buildInfoRow(
                        Icons.badge,
                        "ID Number",
                        _patientIdNumber,
                        isImportant: true,
                      ),
                      _buildInfoRow(Icons.cake, "Age", _calculatedAge ?? '...'),
                      _buildInfoRow(
                        Icons.male,
                        "Gender",
                        _calculatedGender ?? '...',
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final userId = widget.data['userId'];
                            if (userId != null &&
                                userId.toString().isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          UserDetailsScreen(userId: userId),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('User profile not found.'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.person_outline),
                          label: const Text('View Patient Profile'),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // Schedule Information
                    if (date != null)
                      _buildSectionCard("Schedule", [
                        _buildInfoRow(
                          Icons.calendar_today,
                          "Date",
                          DateFormat('EEE, MMM d, yyyy').format(date),
                        ),
                        _buildInfoRow(Icons.access_time, "Time", time),
                        if (createdAt != null)
                          _buildInfoRow(
                            Icons.create,
                            "Created At",
                            DateFormat(
                              'MMM d, yyyy - h:mm a',
                            ).format(createdAt.toDate()),
                          ),
                        if (updatedAt != null)
                          _buildInfoRow(
                            Icons.update,
                            "Last Updated",
                            DateFormat(
                              'MMM d, yyyy - h:mm a',
                            ).format(updatedAt.toDate()),
                          ),
                      ]),

                    const SizedBox(height: 20),

                    // Reason & Notes
                    _buildSectionCard(
                      "Appointment Details                        ",
                      [
                        const Text(
                          "Reason for Appointment",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          reason,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            color: Colors.black87,
                          ),
                        ),
                        if (widget.data['notes'] != null &&
                            widget.data['notes'].toString().isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            "Additional Notes",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Text(
                              widget.data['notes'],
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
    );
  }
}
