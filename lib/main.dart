import 'package:e_hospital/firebase_auth/signup.dart';
import 'package:e_hospital/screens/patient/home/home.dart';
import 'package:flutter/material.dart';
import 'firebase_auth/signin.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'eHospital',
      debugShowCheckedModeBanner: false,
      home: const SignupPage(),
    );
  }
}


