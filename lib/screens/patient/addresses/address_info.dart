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
      'phone': _phoneController.text.trim(),
      'nextOfKin': _nextOfKinController.text.trim(),
      'nextOfKin\'sPhone': _nextOfKinController.text.trim(),
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
              _buildTextField(_phoneController, 'Phone Number', keyboardType: TextInputType.phone),
              _buildTextField(_nextOfKinController, 'Next of Kin'),
              _buildTextField(_nextOfKinPhoneController, 'Next of Kin\'s Phone Number'),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _isSaving
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _saveDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.bluea,
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
