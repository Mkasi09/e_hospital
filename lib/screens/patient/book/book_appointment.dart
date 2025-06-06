import 'package:e_hospital/screens/patient/book/ReasonForVisitField.dart';
import 'package:flutter/material.dart';
import 'hospital_dropdown.dart';
import 'doctor_dropdown.dart';
import 'date_picker_tile.dart';
import 'time_slot_selector.dart';
import 'appointment_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> with SingleTickerProviderStateMixin {
  String? _selectedHospital;
  String? _selectedDoctor;
  DateTime? _selectedDate;
  String? _selectedTime;
  final TextEditingController _reasonController = TextEditingController();

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  List<String> _bookedSlots = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
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
    final success = await AppointmentService.submitAppointment(
      context: context,
      selectedHospital: _selectedHospital,
      selectedDoctor: _selectedDoctor,
      selectedDate: _selectedDate,
      selectedTime: _selectedTime,
      reasonController: _reasonController,
    );

    if (success) {
      setState(() {
        _selectedHospital = null;
        _selectedDoctor = null;
        _selectedDate = null;
        _selectedTime = null;
        _reasonController.clear();
        _bookedSlots = [];
      });
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
              HospitalDropdown(
                selectedHospital: _selectedHospital,
                onHospitalSelected: (hospital, doctors) {
                  setState(() {
                    _selectedHospital = hospital;
                    _selectedDoctor = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              DoctorDropdown(
                hospital: _selectedHospital,
                selectedDoctor: _selectedDoctor,
                onDoctorSelected: (doctor) async {
                  setState(() {
                    _selectedDoctor = doctor;
                    _selectedTime = null;
                  });
                  if (_selectedDate != null) {
                    _bookedSlots = await AppointmentService.fetchBookedSlots(doctor!, _selectedDate!);
                  }
                },
              ),
              const SizedBox(height: 16),
              DatePickerTile(
                selectedDate: _selectedDate,
                onDatePicked: (date) async {
                  setState(() => _selectedDate = date);
                  if (_selectedDoctor != null) {
                    _bookedSlots = await AppointmentService.fetchBookedSlots(_selectedDoctor!, date);
                  }
                },
              ),
              const SizedBox(height: 16),
              if (_selectedDoctor != null && _selectedDate != null)
                TimeSlotSelector(
                  selectedDate: _selectedDate!,
                  bookedSlots: _bookedSlots,
                  selectedTime: _selectedTime,
                  onSlotSelected: (slot) => setState(() => _selectedTime = slot),
                ),
              const SizedBox(height: 16),
              ReasonForVisitField(
                controller: _reasonController,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitAppointment,
                child: const Text('Book Appointment'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
