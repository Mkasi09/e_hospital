import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'chatbubble.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, String>> messages = [];
  final String apiKey = "AIzaSyA6tYsJWmtD8_VVurStHlfkRGjUqBsuu8I";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  // Load messages from shared preferences
  Future<void> _loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? messagesJson = prefs.getString('chat_messages');

      if (messagesJson != null && messagesJson.isNotEmpty) {
        final List<dynamic> decodedMessages = json.decode(messagesJson);
        setState(() {
          messages = decodedMessages.map<Map<String, String>>((message) {
            return Map<String, String>.from(message);
          }).toList();
          _isLoading = false;
        });
      } else {
        // If no saved messages, add the initial greeting
        setState(() {
          messages.add({
            "sender": "bot",
            "text": "👋 Hello! I'm your health assistant. How can I help you today with health, fitness, nutrition, or wellness?",
            "time": DateFormat('hh:mm a').format(DateTime.now()),
          });
          _isLoading = false;
        });
        _saveMessages(); // Save the initial message
      }
    } catch (e) {
      print("Error loading messages: $e");
      setState(() {
        messages.add({
          "sender": "bot",
          "text": "👋 Hello! I'm your health assistant. How can I help you today with health, fitness, nutrition, or wellness?",
          "time": DateFormat('hh:mm a').format(DateTime.now()),
        });
        _isLoading = false;
      });
    }
  }

  // Save messages to shared preferences
  Future<void> _saveMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String messagesJson = json.encode(messages);
      await prefs.setString('chat_messages', messagesJson);
    } catch (e) {
      print("Error saving messages: $e");
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;

    setState(() {
      messages.add({
        "sender": "user",
        "text": text,
        "time": DateFormat('hh:mm a').format(DateTime.now()),
      });
      messages.add({"sender": "bot", "text": "typing"});
    });

    _controller.clear();
    await _saveMessages(); // Save after adding new message

    // Multi-turn memory: last 5 messages
    List<Map<String, String>> memory = [];
    int start = messages.length - 6; // last 5 + current user message
    if (start < 0) start = 0;
    for (int i = start; i < messages.length; i++) {
      if (messages[i]["text"] != "typing") {
        memory.add(messages[i]);
      }
    }

    String prompt =
        "You are a helpful health assistant. Only answer health-related questions about wellness, fitness, nutrition, or medical advice.\n";
    for (var msg in memory) {
      String role = msg["sender"] == "user" ? "User" : "Bot";
      prompt += "$role: ${msg["text"]}\n";
    }
    prompt += "User: $text\nBot:";

    // API call
    try {
      final response = await http.post(
        Uri.parse(
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "contents": [
            {"parts": [{"text": prompt}]}
          ]
        }),
      );

      String aiText = "Sorry, I couldn't respond.";
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        aiText = data['candidates'][0]['content']['parts'][0]['text'];
      }

      setState(() {
        messages.removeLast(); // remove typing
        messages.add({
          "sender": "bot",
          "text": aiText,
          "time": DateFormat('hh:mm a').format(DateTime.now()),
        });
      });

      await _saveMessages(); // Save after bot response

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      print("Error sending message: $e");
      setState(() {
        messages.removeLast(); // remove typing
        messages.add({
          "sender": "bot",
          "text": "Sorry, I encountered an error. Please try again.",
          "time": DateFormat('hh:mm a').format(DateTime.now()),
        });
      });
      await _saveMessages(); // Save error message
    }
  }

  // Add a method to clear conversation if needed
  Future<void> _clearConversation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('chat_messages');
      setState(() {
        messages.clear();
        messages.add({
          "sender": "bot",
          "text": "👋 Hello! I'm your health assistant. How can I help you today with health, fitness, nutrition, or wellness?",
          "time": DateFormat('hh:mm a').format(DateTime.now()),
        });
      });
      await _saveMessages(); // Save the cleared state
    } catch (e) {
      print("Error clearing conversation: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Health Chatbot"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearConversation,
            tooltip: "Clear conversation",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                          child: Icon(Icons.medical_services, color: Colors.white),
                        ),
                      ),
                    ChatBubble(
                      text: msg["text"] ?? "",
                      time: msg["time"] ?? "",
                      isUser: isUser,
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
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16),
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
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
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