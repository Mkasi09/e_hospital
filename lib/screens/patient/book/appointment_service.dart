import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentService {
  static final CollectionReference _appointmentsRef =
  FirebaseFirestore.instance.collection('appointments');

  static Future<List<String>> fetchBookedSlots(String doctorId, DateTime selectedDate) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .get();

    final bookedTimes = <String>[];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final Timestamp dateTimestamp = data['date'];
      final String timeString = data['time'];

      final appointmentDate = dateTimestamp.toDate();
      if (DateUtils.isSameDay(appointmentDate, selectedDate)) {
        final parts = timeString.split(':');
        final hour = parts[0].padLeft(2, '0');
        final minute = parts[1].padLeft(2, '0');
        bookedTimes.add('$hour:$minute');
      }
    }

    return bookedTimes;
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'User not logged in';

      final userId = user.uid;

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final patientName = userDoc.data()?['fullName'] ?? 'Unknown Patient';

      final doctorSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isEqualTo: selectedDoctor)
          .limit(1)
          .get();

      if (doctorSnapshot.docs.isEmpty) throw 'Doctor not found';

      final doctorDoc = doctorSnapshot.docs.first;
      final doctorId = doctorDoc.id;

      final parts = selectedTime!.split(':');
      final appointmentDateTime = DateTime(
        selectedDate!.year,
        selectedDate.month,
        selectedDate.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );

      await _appointmentsRef.add({
        'hospital': selectedHospital,
        'doctor': selectedDoctor,
        'doctorId': doctorId,
        'date': Timestamp.fromDate(appointmentDateTime),
        'time': selectedTime,
        'reason': reasonController.text.trim(),
        'createdAt': Timestamp.now(),
        'status': 'pending',
        'userId': userId,
        'patientName': patientName,
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

  static Future<bool> rescheduleAppointment({
    required BuildContext context,
    required String appointmentId,
    required String newHospital,
    required String newDoctor,
    required DateTime newDate,
    required String newTime,
    required TextEditingController reasonController,
  }) async {
    try {
      final parts = newTime.split(':');
      final appointmentDateTime = DateTime(
        newDate.year,
        newDate.month,
        newDate.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );

      final startOfDay = DateTime(newDate.year, newDate.month, newDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _appointmentsRef
          .where('doctor', isEqualTo: newDoctor)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      final conflicting = snapshot.docs.any(
            (doc) => doc.id != appointmentId && doc['time'] == newTime,
      );

      if (conflicting) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected time is already booked.')),
        );
        return false;
      }

      await _appointmentsRef.doc(appointmentId).update({
        'hospital': newHospital,
        'doctor': newDoctor,
        'date': Timestamp.fromDate(appointmentDateTime),
        'time': newTime,
        'reason': reasonController.text.trim(),
        'updatedAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment rescheduled successfully.')),
      );
      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reschedule appointment: $e')),
      );
      return false;
    }
  }
}
