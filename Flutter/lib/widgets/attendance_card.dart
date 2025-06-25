import 'package:flutter/material.dart';

class AttendanceCard extends StatelessWidget {
  final String title;
  final String time;
  final String subtitle;
  final TextStyle? timeStyle;
  final TextStyle? subtitleStyle;

  const AttendanceCard({super.key, 
    required this.title,
    required this.time,
    required this.subtitle,
    this.timeStyle,
    this.subtitleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[200],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              time,
              style: timeStyle ??
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: subtitleStyle ?? const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}