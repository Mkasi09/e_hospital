import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_hospital/firebase_auth/set_new_password.dart';
import 'package:e_hospital/firebase_auth/signin.dart';
import 'package:e_hospital/firebase_auth/user_id.dart';
import 'package:e_hospital/screens/doctor/home/doctor_home.dart';
import 'package:e_hospital/screens/patient/home/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return LoginPage();
    }

    // ✅ Set UID globally
    CurrentUser.uid = user.uid;

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
        final role = data['role'];
        final requiresReset = data['requiresPasswordReset'] == true;

        // If user must reset password, fetch token and pass it to the reset screen
        if (requiresReset) {
          return FutureBuilder<String>(
              future: user.getIdToken(true).then((token) => token!),
            // Get fresh token
            builder: (context, tokenSnapshot) {
              if (tokenSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!tokenSnapshot.hasData) {
                return const Center(child: Text('Unable to retrieve token.'));
              }

              final idToken = tokenSnapshot.data!;
              return SetNewPasswordScreen(
                uid: user.uid,
                idToken: idToken,
              );
            },
          );
        }

        // Route by role
        if (role == 'doctor') {
          return DoctorsHomepage();
        } else if (role == 'patient') {
          return PatientHomeScreen();
        } else {
          return const Center(child: Text('Unknown role.'));
        }
      },
    );
  }
}
