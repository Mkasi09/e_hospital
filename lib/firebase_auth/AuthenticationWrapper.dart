import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_hospital/firebase_auth/signin.dart';
import 'package:e_hospital/screens/doctor/home/doctor_home.dart';
import 'package:e_hospital/screens/patient/home/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return LoginPage(); // or SignupPage
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('User data not found.'));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final role = data['role']; // Make sure you save 'role' in Firestore

        if (role == 'doctor') {
          return DoctorsHomepage();
        } else if (role == 'patient') {
          return PatientHomeScreen(); // or HomeScreen()
        } else {
          return const Center(child: Text('Unknown role.'));
        }
      },
    );
  }
}
