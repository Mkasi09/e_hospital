import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_hospital/screens/patient/home/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../firebase_auth/AuthenticationWrapper.dart';

class AdditionalDetailsScreen extends StatefulWidget {
  const AdditionalDetailsScreen({super.key});

  @override
  State<AdditionalDetailsScreen> createState() =>
      _AdditionalDetailsScreenState();
}

class _AdditionalDetailsScreenState extends State<AdditionalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nextOfKinController = TextEditingController();
  final _nextOfKinPhoneController = TextEditingController();

  String? _selectedGender;
  bool _isSaving = false;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _setupPhoneControllers();
  }

  void _setupPhoneControllers() {
    _phoneController.addListener(() {
      String text = _phoneController.text;
      if (text.startsWith('0')) {
        _phoneController.text = text.substring(1);
        _phoneController.selection = TextSelection.fromPosition(
          TextPosition(offset: _phoneController.text.length),
        );
      }
      if (_phoneController.text.length > 9) {
        _phoneController.text = _phoneController.text.substring(0, 9);
        _phoneController.selection = TextSelection.fromPosition(
          TextPosition(offset: _phoneController.text.length),
        );
      }
    });

    _nextOfKinPhoneController.addListener(() {
      String text = _nextOfKinPhoneController.text;
      if (text.startsWith('0')) {
        _nextOfKinPhoneController.text = text.substring(1);
        _nextOfKinPhoneController.selection = TextSelection.fromPosition(
          TextPosition(offset: _nextOfKinPhoneController.text.length),
        );
      }
      if (_nextOfKinPhoneController.text.length > 9) {
        _nextOfKinPhoneController.text = _nextOfKinPhoneController.text
            .substring(0, 9);
        _nextOfKinPhoneController.selection = TextSelection.fromPosition(
          TextPosition(offset: _nextOfKinPhoneController.text.length),
        );
      }
    });
  }

  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (doc.exists) {
        setState(() {
          _userRole = doc.data()!['role'] ?? 'patient';
        });
      }
    }
  }

  String normalizePhoneNumber(String phone) {
    String trimmed = phone.trim();
    if (trimmed.startsWith('0')) {
      return trimmed.substring(1);
    }
    return trimmed;
  }

  Future<void> _saveDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not authenticated')));
        return;
      }

      final uid = user.uid;

      // Prepare update data
      final updateData = {
        'address': {
          'street': _streetController.text.trim(),
          'city': _cityController.text.trim(),
          'province': _provinceController.text.trim(),
          'postalCode': _postalCodeController.text.trim(),
          'country': _countryController.text.trim(),
        },
        'gender': _selectedGender,
        'phone': "0" + normalizePhoneNumber(_phoneController.text),
        'profileComplete': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only add next of kin fields for patients
      if (_userRole == 'patient') {
        updateData['nextOfKin'] = _nextOfKinController.text.trim();
        updateData['nextOfKinPhone'] =
            "0" + normalizePhoneNumber(_nextOfKinPhoneController.text);
        updateData['hasAddress'] =
            true; // Mark that patient has completed address
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update(updateData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AuthenticationWrapper()),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving details: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _skip() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Skip Profile Completion?'),
            content: const Text(
              'You can complete your profile later, but some features may be limited.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context); // Close the dialog first
                  await _performSkip();
                },
                child: const Text(
                  'Skip Anyway',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _performSkip() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'profileSkipped': true,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can complete your profile later'),
          backgroundColor: Colors.blue,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AuthenticationWrapper()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildPhoneField(
    TextEditingController controller,
    String label, {
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        maxLength: 9,
        decoration: InputDecoration(
          labelText: label,
          prefixText: '+27 ',
          prefixStyle: const TextStyle(fontWeight: FontWeight.bold),
          counterText: '',
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
        ),
        validator:
            required
                ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter $label';
                  }
                  if (!RegExp(r'^[1-9][0-9]{8}$').hasMatch(value.trim())) {
                    return 'Enter valid 9-digit number (without leading 0)';
                  }
                  return null;
                }
                : null,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
        ),
        validator:
            required
                ? (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Enter $label'
                        : null
                : null,
      ),
    );
  }

  Widget _buildGenderDropdown({bool required = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Gender',
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
        ),
        value: _selectedGender,
        items: const [
          DropdownMenuItem(value: 'Male', child: Text('Male')),
          DropdownMenuItem(value: 'Female', child: Text('Female')),
          DropdownMenuItem(value: 'Other', child: Text('Other')),
          DropdownMenuItem(
            value: 'Prefer not to say',
            child: Text('Prefer not to say'),
          ),
        ],
        onChanged: (value) {
          setState(() {
            _selectedGender = value;
          });
        },
        validator:
            required
                ? (value) => value == null ? 'Please select your gender' : null
                : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPatient = _userRole == 'patient';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _skip,
            child:
                _isSaving
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
          ),
        ],
      ),
      body:
          _isSaving
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      const Text(
                        'Complete your profile',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please provide your details to get the most out of the app${isPatient ? ', including emergency contact information' : ''}.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Address Section
                      _buildSectionHeader('Address Information'),
                      _buildTextField(_streetController, 'Street Address'),
                      _buildTextField(_cityController, 'City'),
                      _buildTextField(_provinceController, 'Province/State'),
                      _buildTextField(
                        _postalCodeController,
                        'Postal Code',
                        keyboardType: TextInputType.number,
                      ),
                      _buildTextField(_countryController, 'Country'),

                      const SizedBox(height: 16),

                      // Personal Information Section
                      _buildSectionHeader('Personal Information'),
                      _buildPhoneField(_phoneController, 'Phone Number'),
                      _buildGenderDropdown(),

                      // Next of Kin Section (only for patients)
                      if (isPatient) ...[
                        const SizedBox(height: 16),
                        _buildSectionHeader('Emergency Contact'),
                        _buildTextField(
                          _nextOfKinController,
                          'Next of Kin Name',
                        ),
                        _buildPhoneField(
                          _nextOfKinPhoneController,
                          'Next of Kin Phone Number',
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveDetails,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Save and Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Skip hint
                      Center(
                        child: TextButton(
                          onPressed: _isSaving ? null : _skip,
                          child: const Text(
                            'I\'ll do this later',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _streetController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _nextOfKinController.dispose();
    _nextOfKinPhoneController.dispose();
    super.dispose();
  }
}
