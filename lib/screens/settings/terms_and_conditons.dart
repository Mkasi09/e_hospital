import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatefulWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  State<TermsAndConditionsScreen> createState() =>
      _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen> {
  bool _agreed = false;

  void _handleAgree() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Thank You!"),
        content: const Text("You have agreed to the Terms and Conditions."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Terms & Conditions"),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Please read the following terms and conditions carefully before using the app.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            const ExpansionTile(
              title: Text("1. Acceptance of Terms"),
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "By using this app, you agree to be bound by these terms.",
                  ),
                ),
              ],
            ),
            const ExpansionTile(
              title: Text("2. User Responsibilities"),
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "You agree not to misuse the app and to respect others’ rights.",
                  ),
                ),
              ],
            ),
            const ExpansionTile(
              title: Text("3. Privacy Policy"),
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Your data is protected and handled responsibly. Please read our full privacy policy.",
                  ),
                ),
              ],
            ),
            const ExpansionTile(
              title: Text("4. Modifications"),
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "We may update these terms from time to time. Continued use implies acceptance.",
                  ),
                ),
              ],
            ),
            const ExpansionTile(
              title: Text("5. Contact Us"),
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "For any questions, email us at support@example.com.",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // ✅ Checkbox
            Row(
              children: [
                Checkbox(
                  value: _agreed,
                  onChanged: (value) {
                    setState(() {
                      _agreed = value ?? false;
                    });
                  },
                ),
                const Expanded(
                  child: Text("I agree to the Terms and Conditions."),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ✅ Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _agreed ? _handleAgree : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("Agree and Continue"),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
