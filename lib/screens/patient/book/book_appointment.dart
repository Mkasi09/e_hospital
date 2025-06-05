import 'package:flutter/material.dart';

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

  final Map<String, List<String>> _hospitalDoctorMap = {
    'City Hospital': ['Dr. Smith', 'Dr. Patel'],
    'Green Valley Clinic': ['Dr. Johnson', 'Dr. Kim'],
  };

  final List<String> _allSlots = [
    '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '12:00', '14:00', '14:30', '15:00', '15:30', '16:00'
  ];

  // Simulate booked time slots per doctor per day
  List<String> getBookedSlots(String doctor, DateTime date) {
    if (doctor == 'Dr. Smith') return ['10:00', '11:30'];
    if (doctor == 'Dr. Kim') return ['09:30', '15:00'];
    return [];
  }

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
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

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _submitAppointment() {
    if (_selectedHospital == null || _selectedDoctor == null || _selectedDate == null || _selectedTime == null || _reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all the fields.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Appointment booked successfully.')),
    );

    setState(() {
      _selectedHospital = null;
      _selectedDoctor = null;
      _selectedDate = null;
      _selectedTime = null;
      _reasonController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<String> doctors = _selectedHospital != null ? _hospitalDoctorMap[_selectedHospital]! : [];

    final List<String> availableSlots = (_selectedDoctor != null && _selectedDate != null)
        ? _allSlots.where((slot) => !getBookedSlots(_selectedDoctor!, _selectedDate!).contains(slot)).toList()
        : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildCard(
                child: DropdownButtonFormField<String>(
                  value: _selectedHospital,
                  decoration: const InputDecoration(labelText: 'Select Hospital'),
                  items: _hospitalDoctorMap.keys.map((hospital) {
                    return DropdownMenuItem(value: hospital, child: Text(hospital));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedHospital = value;
                      _selectedDoctor = null;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              _buildCard(
                child: DropdownButtonFormField<String>(
                  value: _selectedDoctor,
                  decoration: const InputDecoration(labelText: 'Select Doctor'),
                  items: doctors.map((doctor) {
                    return DropdownMenuItem(value: doctor, child: Text(doctor));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDoctor = value;
                      _selectedTime = null;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              _buildCard(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.blue),
                  title: Text(_selectedDate == null
                      ? 'Pick a Date'
                      : 'Date: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedDoctor != null && _selectedDate != null)
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Available Time Slots:', style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: availableSlots.map((slot) {
                          return ChoiceChip(
                            label: Text(slot),
                            selected: _selectedTime == slot,
                            onSelected: (_) {
                              setState(() => _selectedTime = slot);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              _buildCard(
                child: TextField(
                  controller: _reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Reason for Visit',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitAppointment,
                  icon: const Icon(Icons.check),
                  label: const Text('Book Appointment'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    );
  }
}
