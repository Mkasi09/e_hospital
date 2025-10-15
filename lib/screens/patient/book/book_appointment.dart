import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_hospital/screens/patient/book/ReasonForVisitField.dart';
import 'package:e_hospital/screens/patient/book/reschudule/reschudule_appoitment_service.dart';
import 'package:flutter/material.dart';
import 'hospital_dropdown.dart';
import 'doctor_dropdown.dart';
import 'date_picker_tile.dart';
import 'time_slot_selector.dart';
import 'appointment_service.dart';

// Add a simple toggle or radio buttons for Pay Now / Pay Later
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
  String? _appointmentType;
  int? _currentFee;
  bool _payNow = true; // ✅ Default is pay now

  final TextEditingController _reasonController = TextEditingController();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  List<String> _bookedSlots = [];

  final List<String> _appointmentTypes = [
    "Consultation",
    "Follow-up",
    "Checkup-up",
    "Treatment",
    "Emergency",
  ];

  final Map<String, int> _appointmentFees = {
    "Consultation": 50,
    "Follow-up": 30,
    "Checkup-up": 40,
    "Treatment": 70,
    "Emergency": 100,
  };

  @override
  void initState() {
    super.initState();

    if (widget.isRescheduling && widget.existingData != null) {
      final data = widget.existingData!;
      _selectedHospital = data['hospital'];
      _selectedDoctor = {'name': data['doctor'], 'specialty': ''};
      _selectedDate = (data['date'] as Timestamp).toDate();
      _selectedTime = data['time'];
      _reasonController.text = data['reason'] ?? '';
      _appointmentType = data['appointmentType'];
      _currentFee =
          _appointmentType != null ? _appointmentFees[_appointmentType!] : null;

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

  void _loadBookedSlots() async {
    if (_selectedDoctor != null && _selectedDate != null) {
      final slots = await AppointmentService.fetchBookedSlots(
        _selectedDoctor!['id']!,
        _selectedDate!,
      );
      setState(() => _bookedSlots = slots);
    }
  }

  void _submitAppointment() async {
    if (_appointmentType == null || _currentFee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an appointment type")),
      );
      return;
    }

    bool success;

    {
      success = await AppointmentService.submitAppointment(
        context: context,
        selectedHospital: _selectedHospital,
        selectedDoctor: _selectedDoctor!['name']!,
        selectedDate: _selectedDate,
        selectedTime: _selectedTime,
        reasonController: _reasonController,
        appointmentType: _appointmentType!,
        fee: _currentFee!,
        payNow: _payNow,
      );
    }

    if (success && !widget.isRescheduling) {
      setState(() {
        _selectedHospital = null;
        _selectedDoctor = null;
        _selectedDate = null;
        _selectedTime = null;
        _appointmentType = null;
        _currentFee = null;
        _reasonController.clear();
        _bookedSlots = [];
        _payNow = true;
      });
    } else if (success) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        centerTitle: true,
        backgroundColor: const Color(0xFF00796B),
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        color: const Color(0xFFE0F2F1),
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
                onDoctorSelected: (doctor) {
                  setState(() => _selectedDoctor = doctor);
                  _loadBookedSlots();
                },
              ),
              const SizedBox(height: 16),
              DatePickerTile(
                selectedDate: _selectedDate,
                onDatePicked: (date) {
                  setState(() => _selectedDate = date);
                  _loadBookedSlots();
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

              // Appointment Type Dropdown
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
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
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
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

              // Show Payment Options and Fee only if everything is selected
              if (_selectedHospital != null &&
                  _selectedDoctor != null &&
                  _selectedDate != null &&
                  _selectedTime != null &&
                  _appointmentType != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🆕 Payment Option
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
                              onChanged:
                                  (val) => setState(() => _payNow = val!),
                            ),
                          ),
                          ListTile(
                            title: const Text('Pay Later (Credit up to R150)'),
                            leading: Radio<bool>(
                              value: false,
                              groupValue: _payNow,
                              onChanged:
                                  (val) => setState(() => _payNow = val!),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    // Fee Display
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          const Icon(Icons.payment, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            '$_appointmentType Fee: R${_currentFee ?? 0}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 16),
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
                      ? 'Book & Pay R$_currentFee'
                      : 'Book & Pay Later',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
