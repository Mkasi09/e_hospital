import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../firebase_auth/AuthenticationWrapper.dart';


class AdditionalDetailsScreen extends StatefulWidget {
  const AdditionalDetailsScreen({super.key});

  @override
  State<AdditionalDetailsScreen> createState() => _AdditionalDetailsScreenState();
}

class _AdditionalDetailsScreenState extends State<AdditionalDetailsScreen> {
  @override
  void initState() {
    super.initState();

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
        _nextOfKinPhoneController.text = _nextOfKinPhoneController.text.substring(0, 9);
        _nextOfKinPhoneController.selection = TextSelection.fromPosition(
          TextPosition(offset: _nextOfKinPhoneController.text.length),
        );
      }
    });
  }

  final _formKey = GlobalKey<FormState>();

  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nextOfKinController = TextEditingController();
  final _nextOfKinPhoneController = TextEditingController();

  bool _isSaving = false;

  String normalizePhoneNumber(String phone) {
    String trimmed = phone.trim();
    if (trimmed.startsWith('0')) {
      return trimmed.substring(1);
    }
    return trimmed;
  }

  void _saveDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'address': {
        'street': _streetController.text.trim(),
        'city': _cityController.text.trim(),
        'province': _provinceController.text.trim(),
        'postalCode': _postalCodeController.text.trim(),
        'country': _countryController.text.trim(),
      },
      'phone': "0"+normalizePhoneNumber(_phoneController.text),
      'nextOfKin': _nextOfKinController.text.trim(),
      'nextOfKin\'sPhone': "0"+normalizePhoneNumber(_nextOfKinPhoneController.text),
      'profileComplete': true,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Details saved successfully')),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => AuthenticationWrapper()),
    );
  }


  void _skip() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => AuthenticationWrapper()),
    );
  }
  Widget _buildPhoneField(TextEditingController controller, String label, {required TextInputType keyboardType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        maxLength: 9,
        decoration: InputDecoration(
          labelText: label,
          prefixText: '+27 ',
          counterText: '', // hides character counter
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Enter $label';
          }
          if (!RegExp(r'^[1-9][0-9]{8}$').hasMatch(value.trim())) {
            return 'Enter valid 9-digit number without 0';
          }
          return null;
        },
      ),
    );
  }


  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) =>
        value == null || value.trim().isEmpty ? 'Enter $label' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(''),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _skip,
            child: const Text(
              'Skip',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),

        child: Form(

          key: _formKey,
          child: Column(

            children: [
              const Text(
                'Complete your details',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 10),

              _buildTextField(_streetController, 'Street Address'),
              _buildTextField(_cityController, 'City'),
              _buildTextField(_provinceController, 'Province/State'),
              _buildTextField(_postalCodeController, 'Postal Code'),
              _buildTextField(_countryController, 'Country'),
              _buildPhoneField(_phoneController, 'Phone Number', keyboardType: TextInputType.phone),
              _buildTextField(_nextOfKinController, 'Next of Kin'),
              _buildPhoneField(_nextOfKinPhoneController, 'Next of Kin\'s Phone Number', keyboardType: TextInputType.phone),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _isSaving
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _saveDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Save and Continue'),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
