import 'package:e_hospital/screens/add_data_to_firebase/add_bulk_data.dart';
import 'package:e_hospital/screens/settings/dark_mode.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'firebase_auth/set_new_password.dart';
import 'firebase_auth/signup.dart';
import 'firebase_auth/signin.dart';
import 'screens/patient/home/home.dart';
import 'firebase_auth/AuthenticationWrapper.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const MyApp(),
    ),
  );

  if (WebViewPlatform.instance == null) {
    if (WebViewPlatform.instance == null) {
      if (WebViewPlatform.instance == null) {
        WebViewPlatform.instance = WebKitWebViewPlatform(); // iOS
      }
      WebViewPlatform.instance = AndroidWebViewPlatform(); // Android
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      title: 'eHospital',
      theme: ThemeData(
        scaffoldBackgroundColor: Color(0xFFE0F2F1), // ✅ Screen background
        primarySwatch: Colors.teal, // ✅ Widgets & buttons teal
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF00796B), // ✅ AppBar teal
          foregroundColor: Colors.white, // ✅ AppBar text/icons white
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black, // ✅ Dark mode background
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      themeMode: themeNotifier.themeMode,
      debugShowCheckedModeBanner: false,
      home: PatientHomeScreen(),
    );
  }
}
