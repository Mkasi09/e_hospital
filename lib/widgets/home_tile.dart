import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DashboardCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color; // new

  const DashboardCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.teal, // default hospital teal
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        shadowColor: color.withOpacity(0.3),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 40,
                color: color, // dynamic hospital color
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
