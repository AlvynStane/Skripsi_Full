import 'package:flutter/material.dart';
import 'package:skripsi/constants/app_colors.dart';

class EmployeeDetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const EmployeeDetailItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: AppColors.primary),
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(value),
        ),
        const Divider(),
      ],
    );
  }
}