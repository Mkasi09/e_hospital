import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentService {
  static Future<List<String>> fetchBookedSlots(String doctor, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctor', isEqualTo: doctor)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    return snapshot.docs.map((doc) => doc['time'] as String).toList();
  }

  static Future<bool> submitAppointment({
    required BuildContext context,
    required String? selectedHospital,
    required String? selectedDoctor,
    required DateTime? selectedDate,
    required String? selectedTime,
    required TextEditingController reasonController,
  }) async {
    if ([selectedHospital, selectedDoctor, selectedDate, selectedTime].contains(null) ||
        reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all the fields.')),
      );
      return false;
    }

    try {
      final parts = selectedTime!.split(':');
      final appointmentDateTime = DateTime(
        selectedDate!.year,
        selectedDate.month,
        selectedDate.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );

      await FirebaseFirestore.instance.collection('appointments').add({
        'hospital': selectedHospital,
        'doctor': selectedDoctor,
        'date': Timestamp.fromDate(appointmentDateTime),
        'time': selectedTime,
        'reason': reasonController.text.trim(),
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment booked successfully.')),
      );
      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to book appointment: $e')),
      );
      return false;
    }
  }
}
