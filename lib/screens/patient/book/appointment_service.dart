import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AppointmentService {
  static final CollectionReference _appointmentsRef =
  FirebaseFirestore.instance.collection('appointments');
  static final CollectionReference _notificationsRef =
  FirebaseFirestore.instance.collection('notifications');

  static Future<List<String>> fetchBookedSlots(String doctorId, DateTime selectedDate) async {
    // Existing implementation remains the same
    final snapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .get();

    final bookedTimes = <String>[];

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
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

  static Future<void> _sendNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? additionalData,
  }) async {
    await _notificationsRef.add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'timestamp': Timestamp.now(),
      'isRead': false,
      'additionalData': additionalData,
    });
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

      // Create the appointment
      final appointmentRef = await _appointmentsRef.add({
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

      // Send notification to patient
      await _sendNotification(
        userId: userId,
        title: 'Appointment Confirmed',
        body: 'Your appointment with Dr. $selectedDoctor at $selectedHospital on ${DateFormat('MMM dd, yyyy').format(selectedDate)} at $selectedTime has been booked.',
        type: 'appointment',
        additionalData: {
          'appointmentId': appointmentRef.id,
          'doctorId': doctorId,
        },
      );

      // Send notification to doctor
      await _sendNotification(
        userId: doctorId,
        title: 'New Appointment',
        body: '$patientName has booked an appointment on ${DateFormat('MMM dd, yyyy').format(selectedDate)} at $selectedTime.',
        type: 'doctor_appointment',
        additionalData: {
          'appointmentId': appointmentRef.id,
          'patientId': userId,
        },
      );

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

      // Get existing appointment data
      final appointmentDoc = await _appointmentsRef.doc(appointmentId).get();
      final appointmentData = appointmentDoc.data() as Map<String, dynamic>;
      final patientId = appointmentData['userId'];
      final doctorId = appointmentData['doctorId'];
      final patientName = appointmentData['patientName'];

      // Update the appointment
      await _appointmentsRef.doc(appointmentId).update({
        'hospital': newHospital,
        'doctor': newDoctor,
        'date': Timestamp.fromDate(appointmentDateTime),
        'time': newTime,
        'reason': reasonController.text.trim(),
        'updatedAt': Timestamp.now(),
      });

      // Send notification to patient about reschedule
      await _sendNotification(
        userId: patientId,
        title: 'Appointment Rescheduled',
        body: 'Your appointment with Dr. $newDoctor has been rescheduled to ${DateFormat('MMM dd, yyyy').format(newDate)} at $newTime.',
        type: 'appointment',
        additionalData: {
          'appointmentId': appointmentId,
          'doctorId': doctorId,
        },
      );

      // Send notification to doctor about reschedule
      await _sendNotification(
        userId: doctorId,
        title: 'Appointment Rescheduled',
        body: '$patientName has rescheduled their appointment to ${DateFormat('MMM dd, yyyy').format(newDate)} at $newTime.',
        type: 'doctor_appointment',
        additionalData: {
          'appointmentId': appointmentId,
          'patientId': patientId,
        },
      );

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