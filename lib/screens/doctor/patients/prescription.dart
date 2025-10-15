import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfessionalPrescriptionDialog extends StatefulWidget {
  final String userId;

  const ProfessionalPrescriptionDialog({Key? key, required this.userId})
    : super(key: key);

  @override
  State<ProfessionalPrescriptionDialog> createState() =>
      _ProfessionalPrescriptionDialogState();
}

class _ProfessionalPrescriptionDialogState
    extends State<ProfessionalPrescriptionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _diagnosisController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSubmitting = false;
  String? _doctorName;

  // List to store multiple medications
  final List<Medication> _medications = [];

  final List<String> _commonMedications = [
    'Amoxicillin 500mg',
    'Ibuprofen 400mg',
    'Paracetamol 500mg',
    'Lisinopril 10mg',
    'Metformin 500mg',
    'Atorvastatin 20mg',
    'Omeprazole 20mg',
    'Amlodipine 5mg',
    'Metoprolol 25mg',
    'Levothyroxine 50mcg',
    'Azithromycin 250mg',
    'Cephalexin 500mg',
    'Prednisone 10mg',
    'Albuterol Inhaler',
    'Insulin Glargine',
  ];

  @override
  void initState() {
    super.initState();
    _fetchDoctorName();
    // Start with one empty medication
    _medications.add(Medication());
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _instructionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchDoctorName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        setState(() {
          _doctorName = doc.data()?['name'] ?? 'Doctor';
        });
      }
    } catch (_) {
      _doctorName = 'Doctor';
    }
  }

  // Medication management methods
  void _addMedication() {
    setState(() {
      _medications.add(Medication());
    });
  }

  void _removeMedication(int index) {
    if (_medications.length > 1) {
      setState(() {
        _medications.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one medication is required'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _updateMedication(int index, Medication medication) {
    setState(() {
      _medications[index] = medication;
    });
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  String? _validateMedication(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Medication name is required';
    }
    if (value.length < 2) {
      return 'Please enter a valid medication name';
    }
    return null;
  }

  String? _validateDosage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Dosage is required';
    }
    if (!RegExp(r'^[0-9].*').hasMatch(value)) {
      return 'Please enter a valid dosage (e.g., 1 tablet, 500mg)';
    }
    return null;
  }

  Future<void> _submitPrescription() async {
    // Validate all medications
    for (int i = 0; i < _medications.length; i++) {
      final medication = _medications[i];
      if (medication.name.isEmpty || medication.dosage.isEmpty) {
        _showErrorMessage(
          'Please fill all medication details for medication ${i + 1}',
        );
        return;
      }
    }

    if (!_formKey.currentState!.validate()) {
      _showErrorMessage('Please fill all required fields correctly.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prescription = PrescriptionData(
        userId: widget.userId,
        diagnosis: _diagnosisController.text.trim(),
        medications: _medications,
        instructions: _instructionsController.text.trim(),
        notes: _notesController.text.trim(),
        doctorName: _doctorName ?? 'Unknown Doctor',
        date: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('prescriptions')
          .add(prescription.toFirestore());

      if (!mounted) return;

      Navigator.pop(context, true);
      _showSuccessMessage();
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _showErrorMessage('Database error: ${e.message}');
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage('Unexpected error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Prescription saved successfully.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _loadTemplate() {
    if (_isSubmitting) return;

    setState(() {
      _instructionsController.text = 'Take after meals with plenty of water';
      _notesController.text = 'Follow up in 2 weeks if symptoms persist';
      // Clear existing medications and add one template medication
      _medications.clear();
      _medications.add(
        Medication(
          name: 'Amoxicillin 500mg',
          dosage: '1 tablet',
          frequency: '3 times daily',
          duration: '7 days',
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Template loaded. Please customize as needed.'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearForm() {
    if (_isSubmitting) return;

    _formKey.currentState?.reset();
    _diagnosisController.clear();
    _instructionsController.clear();
    _notesController.clear();
    setState(() {
      _medications.clear();
      _medications.add(Medication());
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Form cleared.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 10),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.teal,
      ),
    ),
  );

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    bool required = false,
    String? hintText,
    String? semanticLabel,
    String? Function(String?)? validator,
  }) {
    return Semantics(
      label: semanticLabel ?? label,
      textField: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: '$label${required ? ' *' : ''}',
            hintText: hintText,
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.teal),
            ),
          ),
          validator:
              validator ??
              (required ? (value) => _validateRequired(value, label) : null),
        ),
      ),
    );
  }

  Widget _buildMedicationCard(int index) {
    final medication = _medications[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medication, size: 20, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Medication ${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const Spacer(),
              if (_medications.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: () => _removeMedication(index),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMedicationField(index, medication),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMedicationFormField(
                  label: 'Dosage',
                  value: medication.dosage,
                  hintText: 'e.g., 1 tablet, 500mg',
                  onChanged:
                      (value) => _updateMedication(
                        index,
                        medication.copyWith(dosage: value),
                      ),
                  validator: _validateDosage,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMedicationFormField(
                  label: 'Frequency',
                  value: medication.frequency,
                  hintText: 'e.g., 3 times daily',
                  onChanged:
                      (value) => _updateMedication(
                        index,
                        medication.copyWith(frequency: value),
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMedicationFormField(
            label: 'Duration',
            value: medication.duration,
            hintText: 'e.g., 7 days, 2 weeks',
            onChanged:
                (value) => _updateMedication(
                  index,
                  medication.copyWith(duration: value),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationFormField({
    required String label,
    required String value,
    required String hintText,
    required Function(String) onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildMedicationField(int index, Medication medication) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return _commonMedications.where((String option) {
          return option.toLowerCase().contains(
            textEditingValue.text.toLowerCase(),
          );
        });
      },
      onSelected: (String selection) {
        _updateMedication(index, medication.copyWith(name: selection));
      },
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController textEditingController,
        FocusNode focusNode,
        VoidCallback onFieldSubmitted,
      ) {
        textEditingController.text = medication.name;
        return TextFormField(
          controller: textEditingController,
          decoration: InputDecoration(
            labelText: 'Medication Name *',
            hintText: 'e.g., Amoxicillin 500mg',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onChanged:
              (value) =>
                  _updateMedication(index, medication.copyWith(name: value)),
          validator: _validateMedication,
        );
      },
      optionsViewBuilder: (
        BuildContext context,
        AutocompleteOnSelected<String> onSelected,
        Iterable<String> options,
      ) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return ListTile(
                    leading: const Icon(Icons.medication, size: 20),
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header (same as before)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal, Color(0xFF008080)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.medical_services,
                    color: Colors.white,
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Medical Prescription',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Date: ${DateTime.now().toString().split(' ')[0]}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        if (_doctorName != null)
                          Text(
                            'Dr. $_doctorName',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed:
                        _isSubmitting ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: Colors.grey[50],
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _clearForm,
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text('Clear All'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _loadTemplate,
                      icon: const Icon(Icons.content_copy, size: 18),
                      label: const Text('Use Template'),
                    ),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Diagnosis'),
                      _buildFormField(
                        label: 'Diagnosis',
                        controller: _diagnosisController,
                        maxLines: 2,
                        required: true,
                        hintText: 'Enter patient diagnosis',
                      ),

                      _buildSectionHeader('Medication Details'),
                      ..._medications
                          .asMap()
                          .entries
                          .map((entry) => _buildMedicationCard(entry.key))
                          .toList(),

                      // Add Medication Button
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 20),
                        child: OutlinedButton.icon(
                          onPressed: _isSubmitting ? null : _addMedication,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Another Medication'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),

                      _buildSectionHeader('Instructions'),
                      _buildFormField(
                        label: 'Special Instructions',
                        controller: _instructionsController,
                        maxLines: 3,
                        hintText: 'Take after meals, avoid alcohol...',
                      ),

                      _buildSectionHeader('Additional Notes'),
                      _buildFormField(
                        label: 'Clinical Notes',
                        controller: _notesController,
                        maxLines: 3,
                        hintText: 'Any extra observations...',
                      ),

                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submitPrescription,
                          icon:
                              _isSubmitting
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : const Icon(Icons.save, color: Colors.white),
                          label: Text(
                            _isSubmitting ? 'Saving...' : 'Save Prescription',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Medication data model
class Medication {
  final String name;
  final String dosage;
  final String frequency;
  final String duration;

  Medication({
    this.name = '',
    this.dosage = '',
    this.frequency = '',
    this.duration = '',
  });

  Medication copyWith({
    String? name,
    String? dosage,
    String? frequency,
    String? duration,
  }) {
    return Medication(
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
    );
  }
}

// Enhanced Prescription data model
class PrescriptionData {
  final String userId;
  final String diagnosis;
  final List<Medication> medications;
  final String instructions;
  final String notes;
  final String doctorName;
  final DateTime date;

  PrescriptionData({
    required this.userId,
    required this.diagnosis,
    required this.medications,
    required this.instructions,
    required this.notes,
    required this.doctorName,
    required this.date,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': 'Prescription - $doctorName',
      'uploadedBy': 'doctor',
      'type': 'text',
      'status': 'reviewed',
      'date': FieldValue.serverTimestamp(),
      'diagnosis': diagnosis,
      'medications': medications.map((med) => med.name).toList(),
      'dosages': medications.map((med) => med.dosage).toList(),
      'frequencies': medications.map((med) => med.frequency).toList(),
      'durations': medications.map((med) => med.duration).toList(),
      'instructions': instructions,
      'notes': notes,
      'content': _generateContent(),
      'doctorName': doctorName,
      'timestamp': FieldValue.serverTimestamp(),
      'medicationCount': medications.length,
    };
  }

  String _generateContent() {
    final medicationDetails = medications
        .asMap()
        .entries
        .map((entry) {
          final med = entry.value;
          return '''
Medication ${entry.key + 1}:
- Name: ${med.name}
- Dosage: ${med.dosage}
- Frequency: ${med.frequency}
- Duration: ${med.duration}
''';
        })
        .join('\n');

    return '''
MEDICAL PRESCRIPTION

DIAGNOSIS: $diagnosis

MEDICATION DETAILS:
$medicationDetails
A
INSTRUCTIONS:
$instructions

ADDITIONAL NOTES:
$notes

Prescribed by: $doctorName
Date: ${date.toIso8601String().split('T')[0]}
Total Medications: ${medications.length}
''';
  }
}
