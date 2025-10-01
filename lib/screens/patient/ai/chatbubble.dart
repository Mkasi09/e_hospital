import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final String time;
  final bool isUser;

  const ChatBubble({
    Key? key,
    required this.text,
    required this.time,
    required this.isUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        top: 6,
        bottom: 6,
        left: isUser ? 50 : 8,   // push user bubbles away from left
        right: isUser ? 8 : 50,  // push bot bubbles away from right
      ),
      child: CustomPaint(
        painter: BubblePainter(
          isUser: isUser,
          color: isUser ? Colors.teal : Colors.white,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7, // 70% width
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(
                  color: isUser ? Colors.white70 : Colors.black45,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class BubblePainter extends CustomPainter {
  final bool isUser;
  final Color color;

  BubblePainter({required this.isUser, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(16),
      ));

    // Tail at the TOP
    if (isUser) {
      // Right side tail
      path.moveTo(size.width - 12, 12);
      path.lineTo(size.width, 0);
      path.lineTo(size.width - 2, 20);
    } else {
      // Left side tail
      path.moveTo(12, 12);
      path.lineTo(0, 0);
      path.lineTo(2, 20);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
