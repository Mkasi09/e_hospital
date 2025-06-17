// chat_screen.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String peerName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.peerName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final DatabaseReference _ref = FirebaseDatabase.instance.ref();

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _ref.child('chats/${widget.chatId}/messages').push().set({
      'senderId': widget.currentUserId,
      'text': text,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messagesRef = _ref.child('chats/${widget.chatId}/messages').orderByChild('timestamp');

    return Scaffold(
      appBar: AppBar(title: Text('Chat with ${widget.peerName}')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: messagesRef.onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text('No messages yet.'));
                }

                final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
                final messages = data.entries
                    .map((e) => e.value as Map)
                    .toList()
                  ..sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == widget.currentUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.all(6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[100] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(msg['text']),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Type your message...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _sendMessage,
              )
            ],
          ),
        ],
      ),
    );
  }
}
