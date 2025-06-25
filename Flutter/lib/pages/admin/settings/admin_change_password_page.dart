import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skripsi/constants/app_colors.dart';
import 'package:skripsi/providers/profile_provider.dart';

class AdminChangePasswordPage extends StatefulWidget {
  const AdminChangePasswordPage({super.key});

  @override
  State<AdminChangePasswordPage> createState() => _AdminChangePasswordPageState();
}

class _AdminChangePasswordPageState extends State<AdminChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = {
    "Current Password": TextEditingController(),
    "New Password": TextEditingController(),
    "Confirm New Password": TextEditingController(),
  };
  final _isPasswordVisible = <String, bool>{};

  @override
  void initState() {
    super.initState();
    for (var key in _controllers.keys) {
      _isPasswordVisible[key] = false;
    }
  }

  void _changePassword() async {
    if (_formKey.currentState!.validate()) {
      final currentPassword = _controllers["Current Password"]!.text;
      final newPassword = _controllers["New Password"]!.text;
      try {
        await Provider.of<ProfileProvider>(context, listen: false).changePassword(currentPassword, newPassword);

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password changed successfully!")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Change Password"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _controllers.keys.map((label) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildPasswordField(label),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            "Cancel",
            style: TextStyle(color: AppColors.cancel),
          ),
        ),
        ElevatedButton(
          onPressed: _changePassword,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text(
            "Save",
            style: TextStyle(color: AppColors.text1),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(String label) {
    return TextFormField(
      controller: _controllers[label],
      obscureText: !_isPasswordVisible[label]!,
      decoration: InputDecoration(
        labelText: label,
        border: const UnderlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(_isPasswordVisible[label]! ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _isPasswordVisible[label] = !_isPasswordVisible[label]!;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "$label cannot be empty";
        }
        if (label == "Confirm New Password" && value != _controllers["New Password"]!.text) {
          return "Passwords do not match";
        }
        return null;
      },
    );
  }
}
