import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Future<bool> rescheduleAppointment({
required BuildContext context,
required String docId,
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

// Check for conflicting appointments
final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
final endOfDay = startOfDay.add(const Duration(days: 1));

final snapshot = await FirebaseFirestore.instance
    .collection('appointments')
    .where('doctor', isEqualTo: selectedDoctor)
    .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
    .where('date', isLessThan: Timestamp.fromDate(endOfDay))
    .get();

final conflicting = snapshot.docs.any((doc) =>
doc.id != docId && doc['time'] == selectedTime);

if (conflicting) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Selected time is already booked.')),
);
return false;
}

// Update the appointment
await FirebaseFirestore.instance.collection('appointments').doc(docId).update({
'hospital': selectedHospital,
'doctor': selectedDoctor,
'date': Timestamp.fromDate(appointmentDateTime),
'time': selectedTime,
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
