import 'package:e_hospital/firebase_auth/set_new_password.dart';
import 'package:e_hospital/firebase_auth/signup.dart';
import 'package:e_hospital/screens/patient/home/home.dart';
import 'package:flutter/material.dart';
import 'firebase_auth/AuthenticationWrapper.dart';
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: AuthenticationWrapper(),
    );
  }
}


