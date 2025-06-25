import 'package:e_hospital/screens/patient/chat/service/chat_service.dart';
import 'package:e_hospital/screens/patient/chat/widgets/chat_appbar.dart';
import 'package:e_hospital/screens/patient/chat/widgets/message_bubble.dart';
import 'package:e_hospital/screens/patient/chat/widgets/message_input_field.dart';
import 'package:e_hospital/screens/patient/chat/widgets/typing_indicator.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';


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

  @override
  void initState() {
    super.initState();
    ChatService.markMessagesAsRead(widget.chatId, widget.currentUserId);
  }

  @override
  void dispose() {
    ChatService.setTypingStatus(widget.chatId, widget.currentUserId, false);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatAppBar(peerId: widget.peerId, peerName: widget.peerName),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance
                  .ref('chats/${widget.chatId}/messages')
                  .orderByChild('timestamp')
                  .onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text('No messages yet.'));
                }

                final messages = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
                final sorted = messages.entries.toList()
                  ..sort((a, b) => (a.value['timestamp'] as int)
                      .compareTo(b.value['timestamp'] as int));

                return StreamBuilder<DatabaseEvent>(
                  stream: FirebaseDatabase.instance
                      .ref('chats/${widget.chatId}/typing/${widget.peerId}')
                      .onValue,
                  builder: (context, typingSnapshot) {
                    final isTyping = typingSnapshot.hasData &&
                        typingSnapshot.data!.snapshot.value == true;

                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: sorted.length + (isTyping ? 1 : 0),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                      itemBuilder: (context, index) {
                        if (index < sorted.length) {
                          final msg = Map<String, dynamic>.from(sorted[index].value);
                          return MessageBubble(
                            message: msg,
                            isMe: msg['senderId'] == widget.currentUserId,
                          );
                        } else {
                          return const TypingIndicator();
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
          MessageInputField(
            controller: _messageController,
            chatId: widget.chatId,
            currentUserId: widget.currentUserId,
            peerId: widget.peerId,
            scrollController: _scrollController,
          ),
        ],
      ),
    );
  }
}
