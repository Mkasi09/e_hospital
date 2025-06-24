import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String peerName;
  final String peerId;



  const ChatScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.peerId,
    required this.peerName,
  });


  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _db = FirebaseDatabase.instance;
  Timer? _typingTimer;
  bool _isTyping = false;
  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }
  @override
  void dispose() {
    _setTypingStatus(false);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markMessagesAsRead() async {
    final snapshot = await _db.ref('chats/${widget.chatId}/messages').get();

    if (snapshot.exists) {
      final messages = Map<String, dynamic>.from(snapshot.value as Map);
      for (var entry in messages.entries) {
        final msg = Map<String, dynamic>.from(entry.value);
        if (msg['receiverId'] == widget.currentUserId && msg['read'] == false) {
          await _db.ref('chats/${widget.chatId}/messages/${entry.key}/read').set(true);
        }
      }
    }
  }
  void _setTypingStatus(bool isTyping) {
    if (_isTyping != isTyping) {
      _isTyping = isTyping;
      _db.ref('chats/${widget.chatId}/typing/${widget.currentUserId}').set(isTyping);
    }

    _typingTimer?.cancel();
    if (isTyping) {
      _typingTimer = Timer(const Duration(seconds: 2), () {
        _db.ref('chats/${widget.chatId}/typing/${widget.currentUserId}').set(false);
        _isTyping = false;
      });
    }
  }
  Widget _buildDot(int index) {
    return AnimatedPadding(
      duration: Duration(milliseconds: 300 + (index * 100)),
      padding: EdgeInsets.only(top: index % 2 == 0 ? 0 : 4),
      child: const Text(".", style: TextStyle(fontSize: 20)),
    );
  }
  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final message = {
      'text': text,
      'timestamp': timestamp,
      'senderId': widget.currentUserId,
      'receiverId': widget.peerId, // store peerName if you don’t have ID
      'read': false,
    };

    await _db.ref('chats/${widget.chatId}/messages').push().set(message);

    await _db.ref('chats/${widget.chatId}/meta').update({
      'lastUpdated': timestamp,
    });

    _messageController.clear();
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 100,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();

    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return DateFormat('hh:mm a').format(date);
    } else {
      return DateFormat('MMM dd, yyyy hh:mm a').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DatabaseEvent>(
          stream: FirebaseDatabase.instance.ref('status/${widget.peerId}').onValue,
          builder: (context, snapshot) {
            String statusText = '';

            if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
              final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

              final isOnline = data['online'] == true;
              if (isOnline) {
                statusText = 'Online';
              } else if (data.containsKey('lastSeen')) {
                final lastSeen = DateTime.fromMillisecondsSinceEpoch(data['lastSeen']);
                final formatted = DateFormat('MMM dd, hh:mm a').format(lastSeen);
                statusText = 'Last seen: $formatted';
              } else {
                statusText = 'Offline';
              }
            }


            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(widget.peerName, style: const TextStyle(fontSize: 18)),
                Text(statusText, style: const TextStyle(fontSize: 12)),
              ],
            );
          },
        ),
        centerTitle: true,
      ),
      body: Column(

        children: [
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _db
                  .ref('chats/${widget.chatId}/messages')
                  .orderByChild('timestamp')
                  .onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text('No messages yet.'));
                }

                final messages = Map<String, dynamic>.from(
                    snapshot.data!.snapshot.value as Map);

                final sorted = messages.entries.toList()
                  ..sort((a, b) => (a.value['timestamp'] as int)
                      .compareTo(b.value['timestamp'] as int));

                return StreamBuilder<DatabaseEvent>(
                  stream: _db.ref('chats/${widget.chatId}/typing/${widget.peerId}').onValue,
                  builder: (context, typingSnapshot) {
                    final isTyping = typingSnapshot.hasData &&
                        typingSnapshot.data!.snapshot.value == true;

                    final itemCount = sorted.length + (isTyping ? 1 : 0);

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                      itemCount: itemCount,
                      itemBuilder: (context, index) {
                        if (index < sorted.length) {
                          final msg = Map<String, dynamic>.from(sorted[index].value);
                          final isMe = msg['senderId'] == widget.currentUserId;

                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              padding: const EdgeInsets.all(10),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.blue[100] : Colors.grey[300],
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(12),
                                  topRight: const Radius.circular(12),
                                  bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                                  bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(msg['text'] ?? '', style: const TextStyle(fontSize: 16)),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Text(
                                      _formatTimestamp(msg['timestamp']),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else {
                          // Typing indicator bubble
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text("Typing", style: TextStyle(fontStyle: FontStyle.italic)),
                                  const SizedBox(width: 6),
                                  SizedBox(
                                    width: 24,
                                    child: Row(
                                      children: [
                                        _buildDot(0),
                                        _buildDot(1),
                                        _buildDot(2),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                          ),
                          );
                        }
                      },
                    );
                  },
                );

              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onChanged: (text) {
                      _setTypingStatus(text.isNotEmpty);
                    },
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: null, // Allows the TextField to grow
                    minLines: 1,    // Starts with one line
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),

                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
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
