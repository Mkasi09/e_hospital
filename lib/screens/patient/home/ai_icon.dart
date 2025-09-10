import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class FloatingChatBotIcon extends StatefulWidget {
  final VoidCallback onTap;
  const FloatingChatBotIcon({super.key, required this.onTap});

  @override
  State<FloatingChatBotIcon> createState() => _FloatingChatBotIconState();
}

class _FloatingChatBotIconState extends State<FloatingChatBotIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0,
      end: -10,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          bottom: 60 + _animation.value,
          right: 20,
          child: IconButton(
            icon: Icon(MdiIcons.chatProcessing, size: 50, color: Colors.teal),
            onPressed: widget.onTap,
          ),
        );
      },
    );
  }
}
