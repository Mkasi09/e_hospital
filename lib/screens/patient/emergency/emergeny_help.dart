import 'package:e_hospital/screens/patient/ai/ai_chatbot.dart';
import 'package:e_hospital/screens/settings/help_faq_screen.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyHelpScreen extends StatelessWidget {
  const EmergencyHelpScreen({super.key});

  // Emergency call function
  Future<void> _makeEmergencyCall() async {
    const emergencyNumber = '112'; // Change to your local emergency number
    final Uri telLaunchUri = Uri(scheme: 'tel', path: emergencyNumber);

    try {
      if (await canLaunchUrl(telLaunchUri)) {
        await launchUrl(telLaunchUri);
      } else {
        _showErrorDialog(
          'Could not make emergency call. Please dial $emergencyNumber manually.',
        );
      }
    } catch (e) {
      _showErrorDialog('Error making emergency call: $e');
    }
  }

  // Open maps to find hospitals (without location permission)
  Future<void> _findHospitals() async {
    try {
      // Open maps with hospital search without requiring location
      final Uri mapsUri = Uri(
        scheme: 'https',
        host: 'www.google.com',
        path: '/maps/search/hospitals/near+me',
      );

      if (await canLaunchUrl(mapsUri)) {
        await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to generic maps URL
        final Uri fallbackMapsUri = Uri(
          scheme: 'https',
          host: 'www.google.com',
          path: '/maps',
          queryParameters: {'q': 'hospitals near me'},
        );

        if (await canLaunchUrl(fallbackMapsUri)) {
          await launchUrl(
            fallbackMapsUri,
            mode: LaunchMode.externalApplication,
          );
        } else {
          _showErrorDialog(
            'Could not open maps app. Please search for "hospitals near me" in your maps application.',
          );
        }
      }
    } catch (e) {
      _showErrorDialog('Error opening maps: $e');
    }
  }

  void _showErrorDialog(String message) {
    // Use a GlobalKey or other method to show dialog from stateless widget
    // For simplicity, we'll use a simpler approach in the actual button handlers
    print('Error: $message');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency & Help'),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emergency Section
            const Text(
              'EMERGENCY',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Immediate assistance when you need it most',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: EmergencyButton(
                    icon: Icons.emergency,
                    text: 'Call Emergency',
                    onPressed: () async {
                      try {
                        await _makeEmergencyCall();
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: EmergencyButton(
                    icon: Icons.local_hospital,
                    text: 'Find Hospitals',
                    onPressed: () async {
                      try {
                        await _findHospitals();
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Help Section
            const Text(
              'HELP & SUPPORT',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Get assistance and information',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: ListView(
                children: [
                  HelpOption(
                    icon: Icons.help_outline,
                    color: Colors.green[700]!,
                    text: 'Frequently Asked Questions',
                    subtitle: 'Find answers to common questions',
                    onPressed: () => _showFAQ(context),
                  ),
                  HelpOption(
                    icon: Icons.chat,
                    color: Colors.blue[700]!,
                    text: 'ChatBot',
                    subtitle: 'Chat with our health chatbot',
                    onPressed: () => _openChatSupport(context),
                  ),
                  HelpOption(
                    icon: Icons.phone,
                    color: Colors.purple[700]!,
                    text: 'Customer Support',
                    subtitle: 'Call our support line',
                    onPressed: () => _callSupport(context),
                  ),
                  HelpOption(
                    icon: Icons.email,
                    color: Colors.orange[700]!,
                    text: 'Email Support',
                    subtitle: 'Send us an email',
                    onPressed: () => _emailSupport(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChatSupport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatbotScreen()),
    );
  }

  void _showFAQ(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HelpFaqScreen()),
    );
  }

  Future<void> _callSupport(BuildContext context) async {
    const supportNumber = '18001234567'; // Replace with actual support number
    final Uri telLaunchUri = Uri(scheme: 'tel', path: supportNumber);

    try {
      if (await canLaunchUrl(telLaunchUri)) {
        await launchUrl(telLaunchUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone app')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _emailSupport(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@example.com',
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
}

class EmergencyButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onPressed;

  const EmergencyButton({
    super.key,
    required this.icon,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.red, width: 2),
        ),
        elevation: 6,
        shadowColor: Colors.red.withOpacity(0.4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class HelpOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final String subtitle;
  final VoidCallback onPressed;

  const HelpOption({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
    this.subtitle = '',
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle:
            subtitle.isNotEmpty
                ? Text(subtitle, style: const TextStyle(fontSize: 14))
                : null,
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onPressed,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}

class FAQItem extends StatelessWidget {
  final String question;
  final String answer;

  const FAQItem({super.key, required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(answer, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
