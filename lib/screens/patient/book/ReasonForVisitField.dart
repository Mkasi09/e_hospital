import 'package:flutter/material.dart';

class ReasonForVisitField extends StatelessWidget {
  final TextEditingController controller;

  const ReasonForVisitField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null, // allows multiline input
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Reason for visit',
                hintStyle: TextStyle(color: Colors.grey.shade600),
              ),
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
