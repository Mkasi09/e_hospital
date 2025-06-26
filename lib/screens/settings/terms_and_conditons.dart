import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatefulWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  State<TermsAndConditionsScreen> createState() =>
      _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen> {
  bool _agreed = false;



  Widget buildExpansionTile(String title, String content, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.teal),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              content,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        elevation: 0,
        title: const Text("Terms & Conditions"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "📜 Please read the following terms and conditions carefully before using the app.",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),

            buildExpansionTile("1. Acceptance of Terms",
                "By using this app, you agree to be bound by these terms.",
                Icons.check_circle_outline),
            buildExpansionTile("2. User Responsibilities",
                "You agree not to misuse the app and to respect others’ rights.",
                Icons.verified_user_outlined),
            buildExpansionTile("3. Privacy Policy",
                "Your data is protected and handled responsibly. Please read our full privacy policy.",
                Icons.lock_outline),
            buildExpansionTile("4. Modifications",
                "We may update these terms from time to time. Continued use implies acceptance.",
                Icons.update_outlined),
            buildExpansionTile("5. Contact Us",
                "For any questions, email us at mkasi09@gmail.com.",
                Icons.email_outlined),
            buildExpansionTile("6. Account Security",
                "You are responsible for maintaining the confidentiality of your login credentials and any activities under your account.",
                Icons.security_outlined),
            buildExpansionTile("7. Intellectual Property",
                "All content, trademarks, and data on this app are the property of the app owners unless otherwise indicated.",
                Icons.copyright_outlined),
            buildExpansionTile("8. Termination of Use",
                "We reserve the right to suspend or terminate your access to the app if you violate these terms.",
                Icons.cancel_outlined),
            buildExpansionTile("9. Third-Party Services",
                "The app may contain links to third-party services. We are not responsible for their content or privacy practices.",
                Icons.link_outlined),


            const SizedBox(height: 30),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ],
              ),

      ),
    ])));
  }
}
