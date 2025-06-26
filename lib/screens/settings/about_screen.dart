import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> with TickerProviderStateMixin {
  bool _animate = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() => _animate = true);
    });
  }

  void _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@ehospital.com',
      queryParameters: {'subject': 'Feedback on eHospital App'},
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch email");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About eHospital'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Lottie Animation
          Lottie.asset(
            'assets/hos.json',
            height: 180,
            repeat: true,
          ),

          const SizedBox(height: 10),

          AnimatedOpacity(
            duration: const Duration(milliseconds: 600),
            opacity: _animate ? 1.0 : 0.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              transform: _animate
                  ? Matrix4.identity()
                  : Matrix4.translationValues(0, 50, 0),
              child: Column(
                children: const [
                  Text(
                    'eHospital',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),


          const SizedBox(height: 20),

          // About Card
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About the App',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'eHospital is a smart healthcare appointment app that connects patients with doctors, allowing hassle-free appointment bookings without long queues. Schedule, track, and manage appointments with ease — all from your phone.',
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Developers
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            curve: Curves.decelerate,
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Developers',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text('Sifiso Mabilane', style: TextStyle(fontSize: 16)),
                Text('Given Mkasi', style: TextStyle(fontSize: 16)),
                Text('Mamariri Vanessa Hlakudi', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),

          const SizedBox(height: 30),

          ElevatedButton.icon(
            onPressed: _launchEmail,
            icon: const Icon(Icons.email_outlined),
            label: const Text('Contact Support'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
