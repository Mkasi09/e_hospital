import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _appointmentsMap = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: "confirmed")
        .get();

    final events = <DateTime, List<Map<String, dynamic>>>{};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final date = (data['date'] as Timestamp).toDate();

      final dayKey = DateTime(date.year, date.month, date.day);

      if (events.containsKey(dayKey)) {
        events[dayKey]!.add(data);
      } else {
        events[dayKey] = [data];
      }
    }

    setState(() {
      _appointmentsMap = events;
    });
  }

  List<Map<String, dynamic>> _getAppointmentsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _appointmentsMap[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("You must be logged in as a doctor.")),
      );
    }

    final appointments = _getAppointmentsForDay(_selectedDay ?? _focusedDay);

    return Scaffold(
      appBar: AppBar(title: const Text('My Schedule')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: _getAppointmentsForDay,
          ),
          Text(
            'Appointments: ${appointments.length}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: appointments.isEmpty
                ? const Center(child: Text('No appointments scheduled.'))
                : ListView.builder(
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final data = appointments[index];
                final date = (data['date'] as Timestamp).toDate();

                final startTime = (data['date'] as Timestamp).toDate();
                final endTime = startTime.add(const Duration(minutes: 30));
                final timeRange = '${DateFormat('hh:mm a').format(startTime)} - ${DateFormat('hh:mm a').format(endTime)}';


                return Card(
                  margin:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(Icons.access_time, color: Colors.blue),
                    title: Text(
                      data['patientName'] ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      timeRange,
                      style: const TextStyle(color: Colors.black54),
                    ),

                  ),

                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
