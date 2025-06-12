import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_hospital/screens/patient/book/ReasonForVisitField.dart';
import 'package:flutter/material.dart';
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

class _BookAppointmentScreenState extends State<BookAppointmentScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedHospital;
  Map<String, String>? _selectedDoctor;
  DateTime? _selectedDate;
  String? _selectedTime;
  final TextEditingController _reasonController = TextEditingController();

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  List<String> _bookedSlots = [];

  @override
  void initState() {
    super.initState();

    if (widget.isRescheduling && widget.existingData != null) {
      final data = widget.existingData!;
      _selectedHospital = data['hospital'];
      _selectedDoctor = {
        'name': data['doctor'],
        'specialty': '',
      }; // You can fetch actual specialty if needed
      _selectedDate = (data['date'] as Timestamp).toDate();
      _selectedTime = data['time'];
      _reasonController.text = data['reason'] ?? '';

      AppointmentService.fetchBookedSlots(
        _selectedDoctor!['name']!,
        _selectedDate!,
      ).then((slots) {
        setState(() => _bookedSlots = slots);
      });
    }

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _submitAppointment() async {
    bool success;

    if (widget.isRescheduling && widget.appointmentId != null) {
      success = await AppointmentService.rescheduleAppointment(
        context: context,
        appointmentId: widget.appointmentId!,
        newHospital: _selectedHospital!,
        newDoctor: _selectedDoctor!['name']!,
        newDate: _selectedDate!,
        newTime: _selectedTime!,
        reasonController: _reasonController,
      );
    } else {
      success = await AppointmentService.submitAppointment(
        context: context,
        selectedHospital: _selectedHospital,
        selectedDoctor: _selectedDoctor!['name']!,
        selectedDate: _selectedDate,
        selectedTime: _selectedTime,
        reasonController: _reasonController,
      );
    }

    if (success && !widget.isRescheduling) {
      setState(() {
        _selectedHospital = null;
        _selectedDoctor = null;
        _selectedDate = null;
        _selectedTime = null;
        _reasonController.clear();
        _bookedSlots = [];
      });
    } else if (success) {
      Navigator.of(context).pop(); // return to detail screen or list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment rescheduled successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment'), centerTitle: true),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
             /* HospitalDropdown(
                selectedHospital: _selectedHospital,
                onHospitalSelected: (hospital, doctors) {
                  setState(() {
                    _selectedHospital = hospital;
                    _selectedDoctor = null;
                  });
                },
              ),*/
              const SizedBox(height: 16),
              DoctorDropdown(
                hospital: _selectedHospital,
                selectedDoctor: _selectedDoctor,
                onDoctorSelected: (doctor) async {
                  setState(() {
                    _selectedDoctor = doctor;
                  });
                  if (doctor != null && _selectedDate != null) {
                    final slots = await AppointmentService.fetchBookedSlots(
                      doctor['name']!,
                      _selectedDate!,
                    );
                    setState(() {
                      _bookedSlots = slots;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              DatePickerTile(
                selectedDate: _selectedDate,
                onDatePicked: (date) async {
                  setState(() => _selectedDate = date);
                  if (_selectedDoctor != null) {
                    _bookedSlots = await AppointmentService.fetchBookedSlots(
                      _selectedDoctor!['name']!,
                      date,
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              if (_selectedDoctor != null && _selectedDate != null)
                TimeSlotSelector(
                  selectedDate: _selectedDate!,
                  bookedSlots: _bookedSlots,
                  selectedTime: _selectedTime,
                  onSlotSelected:
                      (slot) => setState(() => _selectedTime = slot),
                ),
              const SizedBox(height: 16),
              ReasonForVisitField(controller: _reasonController),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitAppointment,
                child: const Text('Book Appointment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
