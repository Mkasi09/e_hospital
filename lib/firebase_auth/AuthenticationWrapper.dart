import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_hospital/firebase_auth/set_new_password.dart';
import 'package:e_hospital/firebase_auth/signin.dart';
import 'package:e_hospital/firebase_auth/user_id.dart';
import 'package:e_hospital/screens/doctor/home/doctor_home.dart';
import 'package:e_hospital/screens/patient/home/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class AuthenticationWrapper extends StatelessWidget {
  AuthenticationWrapper({Key? key}) : super(key: key);

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> saveFCMToken(String uid) async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'fcmToken': token,
        });
      }
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
    }
  }

  void goOnline(String uid) {
    final statusRef = FirebaseDatabase.instance.ref('status/$uid');
    statusRef.set({'online': true});
    statusRef.onDisconnect().set({'online': false});
  }

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

        if (requiresReset) {
          return FutureBuilder<String>(
            future: user.getIdToken(true).then((token) => token ?? ""), // force refresh
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

        // Save FCM token and set online status based on role
        if (role == 'doctor') {
          goOnline(user.uid);
          saveFCMToken(user.uid);
          return DoctorsHomepage();
        } else if (role == 'patient') {
          goOnline(user.uid);
          saveFCMToken(user.uid);
          return PatientHomeScreen();
        } else {
          return const Center(child: Text('Unknown role.'));
        }
      },
    );
  }
}
