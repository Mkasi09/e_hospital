import 'package:flutter/material.dart';

class HelpFaqScreen extends StatefulWidget {
  const HelpFaqScreen({super.key});

  @override
  State<HelpFaqScreen> createState() => _HelpFaqScreenState();
}

class _HelpFaqScreenState extends State<HelpFaqScreen> {
  final List<Map<String, String>> allFaqs = [
    {
      "question": "🩺 How do I create an appointment?",
      "answer":
      "Go to the Appointments tab, tap 'Create Appointment', and fill out the required details."
    },
    {
      "question": "🔐 How can I reset my password?",
      "answer":
      "Tap 'Forgot Password' on the login screen. Follow the instructions sent to your email."
    },
    {
      "question": "👤 How do I edit my profile?",
      "answer":
      "Go to Settings > Edit Profile to update your personal information."
    },
    {
      "question": "🔔 Why am I not receiving notifications?",
      "answer":
      "Make sure notifications are enabled in both your phone settings and app settings."
    },
    {
      "question": "❌ Can I cancel an appointment?",
      "answer":
      "Yes. Go to My Appointments, tap the appointment, and choose 'Cancel'."
    },
    {
      "question": "📅 How do I view my upcoming appointments?",
      "answer":
      "Navigate to the My Appointments tab to view all your scheduled visits."
    },
    {
      "question": "💬 How do I contact support?",
      "answer":
      "Go to to the drawer > about > Contact Support. You can send an email the help team directly."
    },
    {
      "question": "🧾 Where can I view my past appointments?",
      "answer":
      "Go to My Appointments > History to see past appointment records."
    },
    {
      "question": "📂 Can I upload medical documents?",
      "answer":
      "Yes, under Appointments or Profile, you can upload relevant documents using the upload button."
    },
  ];

  List<Map<String, String>> filteredFaqs = [];
  String searchText = "";

  @override
  void initState() {
    super.initState();
    filteredFaqs = allFaqs;
  }

  void _filterFaqs(String text) {
    setState(() {
      searchText = text;
      filteredFaqs = allFaqs
          .where((faq) =>
      faq['question']!.toLowerCase().contains(text.toLowerCase()) ||
          faq['answer']!.toLowerCase().contains(text.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        title: const Text('Help & FAQ', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: _filterFaqs,
              decoration: InputDecoration(
                hintText: 'Search FAQ...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 📄 FAQ List or ❌ No Results
          Expanded(
            child: filteredFaqs.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.help_outline, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No results found for "$searchText"',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredFaqs.length,
              itemBuilder: (context, index) {
                final faq = filteredFaqs[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(
                        faq["question"]!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                          child: Text(
                            faq["answer"]!,
                            style: const TextStyle(fontSize: 15, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
