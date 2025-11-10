import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_hospital/firebase_auth/signup.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../screens/patient/addresses/address_info.dart';
import 'AuthenticationWrapper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // Error states for inline messages
  String? _emailError;
  String? _passwordError;

  // Account status check
  Future<Map<String, dynamic>?> _checkAccountStatus(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        return null;
      }

      final data = userDoc.data() as Map<String, dynamic>;
      final statusData = data['accountStatus'] as Map<String, dynamic>? ?? {};

      return statusData;
    } catch (e) {
      return null;
    }
  }

  String _getSuspensionMessage(Map<String, dynamic> statusData) {
    final endDate = statusData['suspensionEndDate'] as Timestamp?;
    final reason =
        statusData['suspensionReason']?.toString() ?? 'Violation of terms';

    if (endDate != null) {
      final formattedDate = DateFormat(
        'MMMM dd, yyyy – HH:mm',
      ).format(endDate.toDate());
      return 'Your account has been suspended until $formattedDate.\nReason: $reason';
    }

    return 'Your account has been suspended.\nReason: $reason';
  }

  String _getBanMessage(Map<String, dynamic> statusData) {
    final reason =
        statusData['banReason']?.toString() ?? 'Serious violation of terms';
    return 'Your account has been permanently banned.\nReason: $reason\n\nContact support if you believe this is a mistake.';
  }

  Future<void> _emailSupport(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@ehospital.com',
      queryParameters: {
        'subject': 'Support Request',
        'body': 'Hello, I need help with...',
      },
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch email app')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showAccountSuspendedDialog(Map<String, dynamic> statusData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Text('Account Suspended'),
              ],
            ),
            content: Text(_getSuspensionMessage(statusData)),
            actions: [
              Row(
                children: [
                  TextButton(
                    onPressed: () => _emailSupport(context),
                    child: const Text('Contact support'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            ],
          ),
    );
  }

  void _showAccountBannedDialog(Map<String, dynamic> statusData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.block, color: Colors.red.shade700),
                const SizedBox(width: 8),
                const Text('Account Banned'),
              ],
            ),
            content: Text(_getBanMessage(statusData)),
            actions: [
              Row(
                children: [
                  TextButton(
                    onPressed: () => _emailSupport(context),
                    child: const Text('Contact support'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            ],
          ),
    );
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    String email = _emailController.text.trim();
    String password = _passwordController.text;

    setState(() {
      _isLoading = true;
      _emailError = null;
      _passwordError = null;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Check account status before proceeding
      Map<String, dynamic>? statusData = await _checkAccountStatus(
        userCredential.user!.uid,
      );

      if (statusData != null) {
        final status = statusData['status']?.toString();

        if (status == 'banned') {
          setState(() {
            _isLoading = false;
          });
          _showAccountBannedDialog(statusData);
          await FirebaseAuth.instance.signOut(); // Sign out the banned user
          return;
        }

        if (status == 'suspended') {
          final endDate = statusData['suspensionEndDate'] as Timestamp?;
          if (endDate != null && endDate.toDate().isAfter(DateTime.now())) {
            // Account is still suspended
            setState(() {
              _isLoading = false;
            });
            _showAccountSuspendedDialog(statusData);
            await FirebaseAuth.instance
                .signOut(); // Sign out the suspended user
            return;
          } else {
            // Suspension period has ended, reactivate account
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userCredential.user!.uid)
                .update({
                  'accountStatus': {
                    'status': 'active',
                    'reactivatedAt': Timestamp.now(),
                  },
                });
          }
        }
      }

      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();

      if (!userDoc.exists) {
        setState(() {
          _emailError = 'User record not found in database';
          _isLoading = false;
        });
        return;
      }

      final data = userDoc.data() as Map<String, dynamic>;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login Successful')));

      // Check if the user's profile is complete
      bool isProfileComplete = data['profileComplete'] == true;
      String userRole = data['role'];

      if (isProfileComplete) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AuthenticationWrapper()),
        );
      } else {
        // Only navigate to AdditionalDetailsScreen if role is patient
        if (userRole == 'patient') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdditionalDetailsScreen()),
          );
        } else {
          // For other roles (doctor, admin, etc.), go to AuthenticationWrapper
          // or you can handle their profile completion differently
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => AuthenticationWrapper()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _emailError = null;
        _passwordError = null;

        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          _passwordError = 'Incorrect password or email, please try again';
        } else if (e.code == 'user-not-found') {
          _emailError = 'No account found with that email';
        } else if (e.code == 'invalid-email') {
          _emailError = 'Enter a valid email address';
        } else if (e.code == 'user-disabled') {
          _emailError = 'This account has been disabled by administrator';
        } else {
          _emailError = null;
          _passwordError = 'Login failed, please try again';
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetPassword() async {
    String email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _emailError = 'Enter your email to reset password';
      });
      return;
    }

    try {
      // Check if the account exists and is not banned/suspended before allowing reset
      try {
        // Try to find the user by email
        final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(
          email,
        );
        if (methods.isEmpty) {
          setState(() {
            _emailError = 'No account found with this email';
          });
          return;
        }
      } catch (e) {
        // Continue with reset even if we can't check status
      }

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset link sent to email')),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _emailError = e.message ?? 'Reset failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Image.asset('assets/icon.png', height: 200),
                const Text(
                  'Login To Your Account',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter your login details to continue',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 8),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.email_outlined),
                    errorText: _emailError,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email';
                    }
                    if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    errorText: _passwordError,
                  ),
                  validator:
                      (value) =>
                          (value == null || value.isEmpty)
                              ? 'Enter password'
                              : null,
                ),
                const SizedBox(height: 30),

                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                        child: const Text('Login'),
                      ),
                    ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: _resetPassword,
                  child: const Text('Forgotten Password?'),
                ),
                const SizedBox(height: 5),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const SignupPage()),
                        );
                      },
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
