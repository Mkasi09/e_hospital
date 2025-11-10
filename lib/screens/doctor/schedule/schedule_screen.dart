import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../appointments/doctors_detailed_appointment.dart';

class AvailabilityRange {
  final TimeOfDay start;
  final TimeOfDay end;

  AvailabilityRange({required this.start, required this.end});

  Map<String, String> toMap() => {
    'start': '${start.hour}:${start.minute}',
    'end': '${end.hour}:${end.minute}',
  };

  static AvailabilityRange fromMap(Map<String, dynamic> map) {
    final startParts = (map['start'] as String).split(':');
    final endParts = (map['end'] as String).split(':');
    return AvailabilityRange(
      start: TimeOfDay(
        hour: int.parse(startParts[0]),
        minute: int.parse(startParts[1]),
      ),
      end: TimeOfDay(
        hour: int.parse(endParts[0]),
        minute: int.parse(endParts[1]),
      ),
    );
  }
}

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _appointmentsMap = {};
  Map<int, List<AvailabilityRange>> _availability = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchAppointments();
    _fetchAvailability();
  }

  Future<void> _fetchAppointments() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('appointments')
            .where('doctorId', isEqualTo: currentUser.uid)
            .where('status', isEqualTo: "confirmed")
            .get();

    final events = <DateTime, List<Map<String, dynamic>>>{};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final date = (data['date'] as Timestamp).toDate();
      final dayKey = DateTime(date.year, date.month, date.day);

      // ✅ DO NOT MODIFY THE FIRESTORE DATA
      // ✅ Store docId + data as a clean object
      final item = {'docId': doc.id, 'data': data};

      if (events.containsKey(dayKey)) {
        events[dayKey]!.add(item);
      } else {
        events[dayKey] = [item];
      }
    }

    setState(() {
      _appointmentsMap = events;
    });
  }

  Future<void> _fetchAvailability() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection('doctor_availability')
            .doc(currentUser.uid)
            .get();

    if (!doc.exists) return;

    final data = doc.data()!;
    final Map<int, List<AvailabilityRange>> availability = {};

    data.forEach((key, value) {
      final day = int.parse(key);
      final ranges =
          (value as List)
              .map((range) => AvailabilityRange.fromMap(range))
              .toList();
      availability[day] = ranges;
    });

    setState(() {
      _availability = availability;
    });
  }

  List<Map<String, dynamic>> _getAppointmentsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _appointmentsMap[key] ?? [];
  }

  Future<void> _setAvailability() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final weekday = (_selectedDay ?? _focusedDay).weekday;

    final start = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (start == null) return;

    final end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: start.hour + 1, minute: start.minute),
    );
    if (end == null) return;

    // Validate time range
    if (end.hour < start.hour ||
        (end.hour == start.hour && end.minute <= start.minute)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newRange = AvailabilityRange(start: start, end: end);
    final updatedRanges = _availability[weekday] ?? [];
    updatedRanges.add(newRange);

    await FirebaseFirestore.instance
        .collection('doctor_availability')
        .doc(currentUser.uid)
        .set({
          weekday.toString(): updatedRanges.map((e) => e.toMap()).toList(),
        }, SetOptions(merge: true));

    _fetchAvailability();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Availability added successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _removeAvailability(int weekday, int index) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final updatedRanges = List<AvailabilityRange>.from(
      _availability[weekday] ?? [],
    );
    updatedRanges.removeAt(index);

    await FirebaseFirestore.instance
        .collection('doctor_availability')
        .doc(currentUser.uid)
        .set({
          weekday.toString(): updatedRanges.map((e) => e.toMap()).toList(),
        }, SetOptions(merge: true));

    _fetchAvailability();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Availability removed'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  String _getWeekdayName(int weekday) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: Card(
            margin: const EdgeInsets.all(20),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    "Authentication Required",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "You must be logged in as a doctor to access this page.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final appointments = _getAppointmentsForDay(_selectedDay ?? _focusedDay);
    final weekday = (_selectedDay ?? _focusedDay).weekday;
    final availabilityRanges = _availability[weekday] ?? [];
    final selectedDate = _selectedDay ?? _focusedDay;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Schedule'),
        elevation: 2,
        shadowColor: Colors.black26,
      ),
      body: SingleChildScrollView(
        // Wrap entire content in SingleChildScrollView
        child: Column(
          children: [
            // Calendar Section
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate:
                          (day) => isSameDay(_selectedDay, day),
                      calendarFormat: CalendarFormat.month,
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      eventLoader: _getAppointmentsForDay,
                      calendarStyle: CalendarStyle(
                        selectedDecoration: BoxDecoration(
                          color: const Color(0xFF00796B),
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Colors.blue[100],
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: BoxDecoration(
                          color: Colors.orange[500],
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Selected Date Info
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('EEEE, MMMM d').format(selectedDate),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${_getWeekdayName(weekday)} Schedule',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Badge(
                            backgroundColor:
                                appointments.isEmpty
                                    ? Colors.grey
                                    : const Color(0xFF00796B),
                            label: Text(appointments.length.toString()),
                            child: const Icon(Icons.calendar_today, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Availability Section
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Availability',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: _setAvailability,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text("Add Slot"),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF00796B),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (availabilityRanges.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.grey[500],
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No availability set for ${_getWeekdayName(weekday)}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(availabilityRanges.length, (
                          index,
                        ) {
                          final range = availabilityRanges[index];
                          return Chip(
                            label: Text(
                              "${range.start.format(context)} - ${range.end.format(context)}",
                              style: const TextStyle(fontSize: 12),
                            ),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted:
                                () => _removeAvailability(weekday, index),
                            backgroundColor: Colors.green[50],
                            labelStyle: TextStyle(color: Colors.green[800]),
                          );
                        }),
                      ),
                  ],
                ),
              ),
            ),

            // Appointments Section - Removed Expanded and wrapped in Container
            // Appointments Section
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            color: Colors.blue[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Appointments',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${appointments.length}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Appointments list or empty state
                      appointments.isEmpty
                          ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 64,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No Appointments',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No appointments scheduled for ${DateFormat('MMM d').format(selectedDate)}',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: appointments.length,
                            itemBuilder: (context, index) {
                              final appointment = appointments[index];
                              final data =
                                  appointment['data']; // ✅ Original Firestore data
                              final docId =
                                  appointment['docId']; // ✅ Real Firestore document ID

                              final startTime =
                                  (data['date'] as Timestamp).toDate();
                              final endTime = startTime.add(
                                const Duration(minutes: 30),
                              );
                              final timeRange =
                                  '${DateFormat('hh:mm a').format(startTime)} - ${DateFormat('hh:mm a').format(endTime)}';

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (
                                            context,
                                          ) => DoctorAppointmentDetailScreen(
                                            docId:
                                                docId, // ✅ use real Firebase doc ID
                                            data: data,
                                          ),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE0F2F1),
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              data['patientName'] ??
                                                  'Unknown Patient',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              timeRange,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: Colors.grey[400],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16), // Add some bottom padding
          ],
        ),
      ),
    );
  }
}
