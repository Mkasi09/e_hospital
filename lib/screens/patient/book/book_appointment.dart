import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_hospital/screens/patient/book/ReasonForVisitField.dart';
import 'package:flutter/material.dart';
import 'availability.dart';
import 'hospital_dropdown.dart';
import 'doctor_dropdown.dart';
import 'date_picker_tile.dart';
import 'time_slot_selector.dart';
import 'appointment_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  final bool isRescheduling;
  final String? appointmentId;
  final Map<String, dynamic>? existingData;

  const BookAppointmentScreen({
    super.key,
    this.isRescheduling = false,
    this.appointmentId,
    this.existingData,
  });

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  String? _selectedHospital;
  Map<String, String>? _selectedDoctor;
  DateTime? _selectedDate;
  String? _selectedTime;
  String? _appointmentType;
  int? _currentFee;
  List<String> _bookedSlots = [];
  bool _payNow = true;

  final TextEditingController _reasonController = TextEditingController();

  final List<String> _appointmentTypes = [
    "Consultation",
    "Follow-up",
    "Checkup",
    "Treatment",
    "Emergency",
  ];

  final Map<String, int> _appointmentFees = {
    "Consultation": 50,
    "Follow-up": 30,
    "Checkup": 40,
    "Treatment": 70,
    "Emergency": 100,
  };

  List<String> _availableSlots = [];

  @override
  void initState() {
    super.initState();

    if (widget.isRescheduling && widget.existingData != null) {
      final data = widget.existingData!;
      _selectedHospital = data['hospital'];
      _selectedDoctor = {'name': data['doctor'], 'id': data['doctorId']};
      _selectedDate = (data['date'] as Timestamp).toDate();
      _selectedTime = data['time'];
      _reasonController.text = data['reason'] ?? '';
      _appointmentType = data['appointmentType'];
      _currentFee =
          _appointmentType != null ? _appointmentFees[_appointmentType!] : null;

      if (_selectedDoctor != null && _selectedDate != null) {
        fetchAvailableSlots(
          _selectedDoctor!['id']!,
          _selectedDate!,
        ).then((slots) => setState(() => _availableSlots = slots));
      }
    }
  }

  Future<List<String>> fetchAvailableSlots(
    String doctorId,
    DateTime selectedDate,
  ) async {
    // 1. Get booked slots
    final bookedSnapshot =
        await FirebaseFirestore.instance
            .collection('appointments')
            .where('doctorId', isEqualTo: doctorId)
            .where('status', isEqualTo: 'confirmed')
            .where(
              'date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(
                DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                ),
              ),
            )
            .where(
              'date',
              isLessThan: Timestamp.fromDate(
                DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day + 1,
                ),
              ),
            )
            .get();

    final bookedSlots =
        bookedSnapshot.docs.map((doc) {
          final date = (doc['date'] as Timestamp).toDate();
          return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
        }).toList();

    // 2. Get doctor availability
    final doc =
        await FirebaseFirestore.instance
            .collection('doctor_availability')
            .doc(doctorId)
            .get();

    if (!doc.exists) return [];

    final weekday = selectedDate.weekday; // 1=Monday
    final rangesData = doc.data()?[weekday.toString()] as List<dynamic>? ?? [];
    final ranges =
        rangesData.map((range) => AvailabilityRange.fromMap(range)).toList();

    // 3. Generate slots
    final slots = <String>[];
    final now = DateTime.now();
    final isToday = DateUtils.isSameDay(now, selectedDate);

    for (var range in ranges) {
      var hour = range.start.hour;
      var minute = range.start.minute;

      while (hour < range.end.hour ||
          (hour == range.end.hour && minute < range.end.minute)) {
        final slotTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          hour,
          minute,
        );
        final slotStr =
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

        if (!bookedSlots.contains(slotStr) &&
            (!isToday || slotTime.isAfter(now))) {
          slots.add(slotStr);
        }

        minute += 30;
        if (minute >= 60) {
          minute = 0;
          hour += 1;
        }
      }
    }

    return slots;
  }

  _loadBookedSlots() async {
    if (_selectedDoctor != null && _selectedDate != null) {
      final startOfDay = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot =
          await FirebaseFirestore.instance
              .collection('appointments')
              .where('doctorId', isEqualTo: _selectedDoctor!['id']!)
              .where(
                'date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              )
              .where('date', isLessThan: Timestamp.fromDate(endOfDay))
              .get();

      final slots = snapshot.docs.map((doc) => doc['time'] as String).toList();

      setState(() {
        _bookedSlots = slots;
      });
    }
  }

  void _loadAvailableSlots() async {
    if (_selectedDoctor != null && _selectedDate != null) {
      final slots = await AppointmentService.fetchAvailableSlots(
        _selectedDoctor!['id']!,
        _selectedDate!,
      );
      setState(() => _availableSlots = slots);
    }
  }

  Future<void> _submitAppointment() async {
    final success = await AppointmentService.submitAppointment(
      context: context,
      selectedHospital: _selectedHospital,
      selectedDoctor: _selectedDoctor?['name'],
      selectedDate: _selectedDate,
      selectedTime: _selectedTime,
      reasonController: _reasonController,
      appointmentType: _appointmentType ?? "Consultation",
      fee: _currentFee ?? 0,
      payNow: _payNow,
    );

    if (success) {
      // Reset form
      setState(() {
        _selectedHospital = null;
        _selectedDoctor = null;
        _selectedDate = null;
        _selectedTime = null;
        _appointmentType = null;
        _currentFee = null;
        _reasonController.clear();
        _availableSlots = [];
        _payNow = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        centerTitle: true,
        backgroundColor: const Color(0xFF00796B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            HospitalDropdown(
              selectedHospital: _selectedHospital,
              onHospitalSelected: (hospital, doctors) {
                setState(() {
                  _selectedHospital = hospital;
                  _selectedDoctor = null;
                  _selectedDate = null;
                  _selectedTime = null;
                  _availableSlots = [];
                });
              },
            ),
            const SizedBox(height: 16),
            DoctorDropdown(
              hospital: _selectedHospital,
              selectedDoctor: _selectedDoctor,
              onDoctorSelected: (doctor) async {
                setState(() => _selectedDoctor = doctor);

                if (_selectedDate != null) {
                  await _loadBookedSlots(); // <-- load booked slots
                  final slots = await fetchAvailableSlots(
                    doctor!['id']!,
                    _selectedDate!,
                  );
                  setState(() => _availableSlots = slots);
                }
              },
            ),
            const SizedBox(height: 16),
            DatePickerTile(
              selectedDate: _selectedDate,
              onDatePicked: (date) async {
                setState(() => _selectedDate = date);

                if (_selectedDoctor != null) {
                  await _loadBookedSlots(); // <-- load booked slots
                  final slots = await fetchAvailableSlots(
                    _selectedDoctor!['id']!,
                    date,
                  );
                  setState(() {
                    _availableSlots = slots;
                    _selectedTime = null;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            if (_selectedDoctor != null && _selectedDate != null)
              if (_selectedDoctor != null && _selectedDate != null)
                TimeSlotSelector(
                  selectedDate: _selectedDate!,
                  availableSlots:
                      _availableSlots, // generated from availability
                  bookedSlots: _bookedSlots, // fetched from Firestore
                  selectedTime: _selectedTime,
                  onSlotSelected:
                      (slot) => setState(() => _selectedTime = slot),
                ),

            const SizedBox(height: 16),
            // Appointment Type
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: DropdownButtonFormField<String>(
                value: _appointmentType,
                decoration: const InputDecoration.collapsed(
                  hintText: "Select Appointment Type",
                ),
                items:
                    _appointmentTypes
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                onChanged: (val) {
                  setState(() {
                    _appointmentType = val;
                    _currentFee = val != null ? _appointmentFees[val] : null;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            ReasonForVisitField(controller: _reasonController),
            const SizedBox(height: 16),
            if (_selectedHospital != null &&
                _selectedDoctor != null &&
                _selectedDate != null &&
                _selectedTime != null &&
                _appointmentType != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment Option
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment Option',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ListTile(
                          title: const Text('Pay Now'),
                          leading: Radio<bool>(
                            value: true,
                            groupValue: _payNow,
                            onChanged: (val) => setState(() => _payNow = val!),
                          ),
                        ),
                        ListTile(
                          title: const Text('Pay Later (Credit up to R150)'),
                          leading: Radio<bool>(
                            value: false,
                            groupValue: _payNow,
                            onChanged: (val) => setState(() => _payNow = val!),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            // Fee display
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.payment, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    _appointmentType == null
                        ? 'Please select an appointment type'
                        : '$_appointmentType Fee: R${_currentFee ?? 0}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitAppointment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
              child: Text(
                _currentFee == null
                    ? 'Book Appointment'
                    : _payNow
                    ? 'Book Appointment & Pay R$_currentFee'
                    : 'Book Appointment & Pay Later',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
