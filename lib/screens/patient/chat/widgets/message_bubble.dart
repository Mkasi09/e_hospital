import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;

  const MessageBubble({super.key, required this.message, required this.isMe});

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return DateFormat('hh:mm a').format(date);
    }
    return DateFormat('MMM dd, yyyy hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = message['type'] == 'image' && message['content'] != null;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(message['content']),
              ),
            if (message['text'] != null && message['text'].toString().isNotEmpty)
              Text(message['text'], style: const TextStyle(fontSize: 16)),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                _formatTimestamp(message['timestamp']),
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
