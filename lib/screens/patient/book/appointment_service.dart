import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_hospital/screens/patient/payments/payfast_web.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../doctor/schedule/schedule_screen.dart';
import '../payments/payfast.dart';

class AppointmentService {
  static final CollectionReference _appointmentsRef = FirebaseFirestore.instance
      .collection('appointments');

  // Fetch booked time slots for a doctor on a given day
  static Future<List<String>> fetchBookedSlots(
    String doctorId,
    DateTime date,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot =
        await _appointmentsRef
            .where('doctorId', isEqualTo: doctorId)
            .where(
              'date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
            )
            .where('date', isLessThan: Timestamp.fromDate(endOfDay))
            .get();

    // Assuming each appointment has a 'time' field like '09:00'
    return snapshot.docs.map((doc) => doc['time'] as String).toList();
  }

  static final CollectionReference _notificationsRef = FirebaseFirestore
      .instance
      .collection('notifications');
  static final CollectionReference _billsRef = FirebaseFirestore.instance
      .collection('bills');

  static Future<List<String>> fetchAvailableSlots(
    String doctorId,
    DateTime date,
  ) async {
    // 1. Fetch booked slots
    final bookedSnapshot =
        await FirebaseFirestore.instance
            .collection('appointments')
            .where('doctorId', isEqualTo: doctorId)
            .where(
              'date',
              isGreaterThanOrEqualTo: DateTime(date.year, date.month, date.day),
            )
            .where(
              'date',
              isLessThan: DateTime(date.year, date.month, date.day, 23, 59, 59),
            )
            .get();

    final bookedSlots =
        bookedSnapshot.docs.map((doc) => doc.data()['time'] as String).toList();

    // 2. Fetch availability
    final availabilityDoc =
        await FirebaseFirestore.instance
            .collection('doctor_availability')
            .doc(doctorId)
            .get();

    final weekday = date.weekday; // Monday = 1
    List<String> availableSlots = [];

    if (availabilityDoc.exists) {
      final data = availabilityDoc.data()!;
      final ranges =
          (data[weekday.toString()] as List?)
              ?.map((r) => AvailabilityRange.fromMap(r))
              .toList();

      if (ranges != null) {
        for (var range in ranges) {
          var slotTime = DateTime(
            0,
            1,
            1,
            range.start.hour,
            range.start.minute,
          );
          final endTime = DateTime(0, 1, 1, range.end.hour, range.end.minute);

          while (!slotTime.isAfter(
            endTime.subtract(const Duration(minutes: 30)),
          )) {
            final slotString =
                '${slotTime.hour.toString().padLeft(2, '0')}:${slotTime.minute.toString().padLeft(2, '0')}';
            availableSlots.add(slotString);
            slotTime = slotTime.add(const Duration(minutes: 30));
          }
        }
      }
    }

    // 3. Remove booked slots
    availableSlots.removeWhere((slot) => bookedSlots.contains(slot));

    return availableSlots;
  }

  static Future<double> fetchOutstandingBalance(String userId) async {
    final snapshot =
        await _billsRef
            .where('userId', isEqualTo: userId)
            .where('status', isEqualTo: 'Unpaid')
            .get();

    double total = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>?; // explicitly nullable
      total += (data?['amount'] ?? 0).toDouble();
    }
    return total;
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

  static Future<void> _createBill({
    required String userId,
    required String doctorName,
    required String appointmentType,
    required double fee,
    required String appointmentId,
    required bool isPaid,
  }) async {
    await _billsRef.add({
      'userId': userId,
      'doctorName': doctorName,
      'appointmentId': appointmentId,
      'appointmentType': appointmentType,
      'title': '$appointmentType Fee - $doctorName',
      'amount': fee,
      'status': isPaid ? 'Paid' : 'Unpaid',
      'timestamp': Timestamp.now(),
    });
  }

  // Handles both Pay Now & Pay Later
  static Future<bool> submitAppointment({
    required BuildContext context,
    required String? selectedHospital,
    required String? selectedDoctor,
    required DateTime? selectedDate,
    required String? selectedTime,
    required TextEditingController reasonController,
    required String appointmentType,
    required int fee,
    required bool payNow,
  }) async {
    if ([
          selectedHospital,
          selectedDoctor,
          selectedDate,
          selectedTime,
        ].contains(null) ||
        reasonController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return false;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'User not logged in';
      final userId = user.uid;

      // Check outstanding balance
      double outstanding = await fetchOutstandingBalance(userId);

      if (!payNow && outstanding + fee > 150) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You cannot defer payment. Your outstanding balance would exceed R150 (currently R${outstanding.toStringAsFixed(2)}).',
            ),
          ),
        );
        return false;
      }

      // Get patient name
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
      final patientName = userDoc.data()?['fullName'] ?? 'Unknown Patient';

      // Find doctorId
      final doctorSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('name', isEqualTo: selectedDoctor)
              .limit(1)
              .get();

      if (doctorSnapshot.docs.isEmpty) throw 'Doctor not found';
      final doctorDoc = doctorSnapshot.docs.first;
      final doctorId = doctorDoc.id;
      final speciality = doctorDoc.data()?['speciality'] ?? 'General';

      // Appointment datetime
      final parts = selectedTime!.split(':');
      final appointmentDateTime = DateTime(
        selectedDate!.year,
        selectedDate.month,
        selectedDate.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );

      // Check conflict
      final startOfDay = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final conflictSnapshot =
          await _appointmentsRef
              .where('doctorId', isEqualTo: doctorId)
              .where(
                'date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              )
              .where('date', isLessThan: Timestamp.fromDate(endOfDay))
              .get();

      final isConflicting = conflictSnapshot.docs.any(
        (doc) => doc['time'] == selectedTime,
      );
      if (isConflicting) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected time is already booked')),
        );
        return false;
      }

      // Create appointment
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
        'appointmentType': appointmentType,
        'fee': fee,
        'speciality': speciality,
      });

      // Payment handling
      if (payNow) {
        // Launch PayFast
        final paid = await PayFastService.initiatePayment(
          context: context,
          amount: fee.toDouble(), // convert int → double
        );

        if (paid == true) {
          await _createBill(
            userId: userId,
            doctorName: selectedDoctor!,
            appointmentType: appointmentType,
            fee: fee.toDouble(),
            appointmentId: appointmentRef.id,
            isPaid: true,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment failed or cancelled')),
          );
          return false;
        }
      } else {
        // Pay later, add unpaid bill
        await _createBill(
          userId: userId,
          doctorName: selectedDoctor!,
          appointmentType: appointmentType,
          fee: fee.toDouble(),
          appointmentId: appointmentRef.id,
          isPaid: false,
        );
      }

      // Notifications
      await _sendNotification(
        userId: userId,
        title: 'Appointment Confirmed',
        body:
            'Your appointment with Dr. $selectedDoctor at $selectedHospital on ${DateFormat('MMM dd, yyyy').format(selectedDate)} at $selectedTime has been booked.',
        type: 'appointment',
        additionalData: {
          'appointmentId': appointmentRef.id,
          'doctorId': doctorId,
        },
      );

      await _sendNotification(
        userId: doctorId,
        title: 'New Appointment',
        body:
            '$patientName has booked an appointment on ${DateFormat('MMM dd, yyyy').format(selectedDate)} at $selectedTime.',
        type: 'doctor_appointment',
        additionalData: {
          'appointmentId': appointmentRef.id,
          'patientId': userId,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            payNow
                ? 'Appointment booked & paid successfully.'
                : 'Appointment booked. You have an outstanding balance of R${(outstanding + fee).toStringAsFixed(2)}',
          ),
        ),
      );

      return true;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to book appointment: $e')));
      return false;
    }
  }
}
