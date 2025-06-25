import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skripsi/constants/app_colors.dart';
import 'package:skripsi/providers/profile_provider.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
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
      try {
        await Provider.of<ProfileProvider>(context, listen: false)
            .changePassword(_controllers["Current Password"]!.text, _controllers["New Password"]!.text);

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password changed successfully!")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Current password is incorrect!")),
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
