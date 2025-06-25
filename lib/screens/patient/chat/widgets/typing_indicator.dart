import 'package:flutter/material.dart';

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  Widget _buildDot(int index) {
    return AnimatedPadding(
      duration: Duration(milliseconds: 300 + index * 100),
      padding: EdgeInsets.only(top: index % 2 == 0 ? 0 : 4),
      child: const Text(".", style: TextStyle(fontSize: 20)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Typing", style: TextStyle(fontStyle: FontStyle.italic)),
            const SizedBox(width: 6),
            Row(children: [_buildDot(0), _buildDot(1), _buildDot(2)]),
          ],
        ),
      ),
    );
  }
}
