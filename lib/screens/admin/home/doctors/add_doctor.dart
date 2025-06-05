// File: lib/screens/admin/add_doctor_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddDoctorScreen extends StatefulWidget {
  const AddDoctorScreen({super.key});

  @override
  State<AddDoctorScreen> createState() => _AddDoctorScreenState();
}

class _AddDoctorScreenState extends State<AddDoctorScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String email = '';
  String specialization = '';
  String licenseNumber = '';
  String experienceYears = '';

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('doctors').add({
        'full name': name,
        'email': email,
        'specialization': specialization,
        'licenseNumber': licenseNumber,
        'experienceYears': experienceYears,
        'approved': true,
        'createdByAdmin': true,
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context); // go back to doctors list
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Doctor')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Full Name'),
                onChanged: (val) => name = val,
                validator: (val) => val!.isEmpty ? 'Enter full name' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                onChanged: (val) => email = val,
                validator: (val) => val!.isEmpty ? 'Enter email' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Specialization'),
                onChanged: (val) => specialization = val,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'License Number'),
                onChanged: (val) => licenseNumber = val,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Years of Experience'),
                onChanged: (val) => experienceYears = val,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Add Doctor'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
