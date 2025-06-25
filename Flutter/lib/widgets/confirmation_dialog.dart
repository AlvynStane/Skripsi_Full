import 'package:flutter/material.dart';
import 'package:skripsi/constants/app_colors.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String cancelText;
  final String confirmText;
  final VoidCallback onConfirm;
  final Color? confirmTextColor;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
    this.cancelText = "Cancel",
    this.confirmText = "Confirm",
    this.confirmTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            cancelText,
            style: const TextStyle(color: AppColors.text2),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.cancel),
          child: Text(
            confirmText,
            style: TextStyle(color: confirmTextColor ?? AppColors.text1),
          ),
        ),
      ],
    );
  }
}
