import 'package:flutter/material.dart';

class ActivityTile extends StatelessWidget {
  final String title;
  final String time;
  final String date;
  final VoidCallback? onTap;

  const ActivityTile({
    super.key,
    required this.title,
    required this.time,
    required this.date,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(date),
        trailing: Text(
          time,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        onTap: onTap,
      ),
    );
  }
}
