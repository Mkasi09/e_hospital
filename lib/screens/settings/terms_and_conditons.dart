import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text("Terms & Conditions"),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "📜 Please read the following terms and conditions carefully before using the app.\n",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SectionTitle(" 1. Acceptance of Terms ✅"),
            SectionBody(
                "By using this app, you agree to be bound by these terms and conditions."),
            SectionTitle(" 2. User Responsibilities 👥"),
            SectionBody(
                "You agree not to misuse the app and to respect others’ rights and privacy. Any violation may result in suspension or termination of your access."),
            SectionTitle(" 3. Privacy Policy 🔒"),
            SectionBody(
                "Your data is protected and handled responsibly. For more details, please read our full privacy policy."),
            SectionTitle(" 4. Modifications 🔁"),
            SectionBody(
                "We may update these terms from time to time. Continued use of the app implies that you accept the updated terms."),
            SectionTitle(" 5. Contact Us 📧"),
            SectionBody(
                "If you have any questions or concerns about these terms, feel free to contact us at mkasi09@gmail.com."),
            SectionTitle(" 6. Account Security 🛡️"),
            SectionBody(
                "You are responsible for maintaining the confidentiality of your login credentials and for all activities that occur under your account."),
            SectionTitle(" 7. Intellectual Property ©️"),
            SectionBody(
                "All content, trademarks, and data on this app are the property of the app owners unless otherwise indicated. Unauthorized use is prohibited."),
            SectionTitle(" 8. Termination of Use 🚫"),
            SectionBody(
                "We reserve the right to suspend or terminate your access to the app if you violate these terms."),
            SectionTitle(" 9. Third-Party Services 🔗"),
            SectionBody(
                "This app may contain links to third-party services. We are not responsible for their content, functionality, or privacy practices."),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Reusable styled widgets
class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.bold,
          color: Colors.teal,
        ),
      ),
    );
  }
}

class SectionBody extends StatelessWidget {
  final String text;
  const SectionBody(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14.5, height: 1.6, color: Colors.black87),
    );
  }
}
