import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_hospital/screens/patient/payments/payfast_web.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppointmentService {
  static final CollectionReference _appointmentsRef = FirebaseFirestore.instance
      .collection('appointments');
  static final CollectionReference _notificationsRef = FirebaseFirestore
      .instance
      .collection('notifications');
  static final CollectionReference _billsRef = FirebaseFirestore.instance
      .collection('bills');

  static Future<List<String>> fetchBookedSlots(
    String doctorId,
    DateTime selectedDate,
  ) async {
    final snapshot =
        await _appointmentsRef.where('doctorId', isEqualTo: doctorId).get();

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
        final payfastUrl =
            'https://payfast.co.za/eng/process?' +
            'merchant_id=21461358&' +
            'merchant_key=pty7ewgdz3yqn&' +
            'return_url=https://yourapp.com/return&' +
            'cancel_url=https://yourapp.com/cancel&' +
            'notify_url=https://yourapp.com/notify&' +
            'amount=${fee.toStringAsFixed(2)}&' +
            'item_name=$appointmentType Payment&' +
            'custom_str1=$userId';

        final paid = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PayFastWebView(url: payfastUrl),
          ),
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
