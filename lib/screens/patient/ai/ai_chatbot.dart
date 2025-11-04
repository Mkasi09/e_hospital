import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, String>> messages = [];
  final String apiKey = "AIzaSyClvkTc8h92DOMSp6v66T-xT8XaQD0LPVw";

  @override
  void initState() {
    super.initState();
    loadMessages();
  }

  /// Load messages from SharedPreferences
  Future<void> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('chat_history');
    if (data != null) {
      setState(() {
        messages = List<Map<String, String>>.from(jsonDecode(data));
      });
    } else {
      // Add initial greeting if no saved messages
      messages.add({
        "sender": "bot",
        "text":
            "👋 Hello! I’m your health assistant. How can I help you today with health, fitness, nutrition, or wellness?",
        "time": DateFormat('hh:mm a').format(DateTime.now()),
      });
      await saveMessages();
    }
  }

  /// Save messages to SharedPreferences
  Future<void> saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('chat_history', jsonEncode(messages));
  }

  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;

    // Add user message & typing indicator
    setState(() {
      messages.add({
        "sender": "user",
        "text": text,
        "time": DateFormat('hh:mm a').format(DateTime.now()),
      });
      messages.add({"sender": "bot", "text": "typing"});
    });
    await saveMessages(); // save after adding user message & typing

    _controller.clear();

    // Multi-turn memory: last 5 messages
    List<Map<String, String>> memory = [];
    int start = messages.length - 6;
    if (start < 0) start = 0;
    for (int i = start; i < messages.length; i++) {
      if (messages[i]["text"] != "typing") {
        memory.add(messages[i]);
      }
    }

    String prompt = """
You are a friendly health assistant chatbot.
- Focus only on health, fitness, nutrition, or wellness.
- clear, and easy to understand.
- Avoid giving diagnosis or prescriptions.


Conversation so far:
""";

    for (var msg in memory) {
      String role = msg["sender"] == "user" ? "User" : "Bot";
      prompt += "$role: ${msg["text"]}\n";
    }
    prompt += "User: $text\nBot:";

    // API call
    final response = await http.post(
      Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey",
      ),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt},
            ],
          },
        ],
      }),
    );

    String aiText = "Sorry, I couldn't respond.";
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      aiText = data['candidates'][0]['content']['parts'][0]['text'];
    }

    // Remove typing & add bot reply, then save
    setState(() {
      messages.removeLast(); // remove typing
      messages.add({
        "sender": "bot",
        "text": aiText,
        "time": DateFormat('hh:mm a').format(DateTime.now()),
      });
    });
    await saveMessages(); // save after adding bot message

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 80,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Health Chatbot"),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg["sender"] == "user";

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment:
                      isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    if (!isUser)
                      const Padding(
                        padding: EdgeInsets.all(6.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Icon(
                            Icons.medical_services,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    Flexible(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth:
                              MediaQuery.of(context).size.width *
                              0.75, // 75% of screen
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.teal : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                          child:
                              msg["text"] == "typing"
                                  ? const TypingIndicator()
                                  : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        msg["text"] ?? "",
                                        style: TextStyle(
                                          color:
                                              isUser
                                                  ? Colors.white
                                                  : Colors.black87,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        msg["time"] ?? "",
                                        style: TextStyle(
                                          color:
                                              isUser
                                                  ? Colors.white70
                                                  : Colors.black45,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                        ),
                      ),
                    ),

                    if (isUser)
                      const Padding(
                        padding: EdgeInsets.all(6.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.blueGrey,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (text) => sendMessage(text),
                    decoration: InputDecoration(
                      hintText: "Ask me about health...",
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => sendMessage(_controller.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Typing dots animation
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({Key? key}) : super(key: key);

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            double t = (_controller.value * 3 - index).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.translate(
                offset: Offset(0, -4 * (1 - t) * (t)),
                child: const Dot(),
              ),
            );
          },
        );
      }),
    );
  }
}

class Dot extends StatelessWidget {
  const Dot({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black54,
      ),
    );
  }
}
