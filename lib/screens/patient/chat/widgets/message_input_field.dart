import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../service/chat_service.dart';

class MessageInputField extends StatelessWidget {
  final TextEditingController controller;
  final String chatId;
  final String currentUserId;
  final String peerId;
  final ScrollController scrollController;

  const MessageInputField({
    super.key,
    required this.controller,
    required this.chatId,
    required this.currentUserId,
    required this.peerId,
    required this.scrollController,
    required FocusNode focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: () async {
              final picker = ImagePicker();
              final picked = await picker.pickImage(
                source: ImageSource.gallery,
              );
              if (picked != null) {
                final file = File(picked.path);
                await ChatService.uploadAndSendImage(
                  file,
                  chatId,
                  currentUserId,
                  peerId,
                );
              }
            },
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (text) {
                ChatService.setTypingStatus(
                  chatId,
                  currentUserId,
                  text.isNotEmpty,
                );
              },
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
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  await ChatService.sendMessage(
                    text,
                    chatId,
                    currentUserId,
                    peerId,
                  );
                  controller.clear();
                  scrollController.animateTo(
                    scrollController.position.maxScrollExtent + 100,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
