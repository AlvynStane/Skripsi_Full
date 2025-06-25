import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:skripsi/constants/app_colors.dart';
import 'package:skripsi/pages/users/profile/change_password_page.dart';
import 'package:skripsi/pages/users/profile/personal_info_page.dart';
import 'package:skripsi/pages/users/profile/terms_and_conditions_page.dart';
import 'package:skripsi/providers/auth_provider.dart';
import 'package:skripsi/providers/profile_provider.dart';
import 'package:skripsi/pages/auth/login_page.dart';
import 'package:skripsi/widgets/confirmation_dialog.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    profileProvider.loadProfile();
  }

  void _logout() async {
    await Provider.of<MyAuthProvider>(context, listen: false).signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _editProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      profileProvider.updateProfile(
        profileProvider.name,
        profileProvider.position,
        profileProvider.email,
        profileImage: File(image.path),
      );
    }
  }

  void _navigateToPersonalInfo() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PersonalInfoPage(),
      ),
    );
  }

  void _navigateToChangePass() {
    showDialog(
      context: context,
      builder: (context) => const ChangePasswordPage(),
    );
  }

  void _navigateToTermsAndConditions() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TermsAndConditionsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 75,
              backgroundImage:
                  profileProvider.profileImage.isNotEmpty ? NetworkImage(profileProvider.profileImage) : null,
              child: profileProvider.profileImage.isEmpty
                  ? const Icon(Icons.admin_panel_settings, size: 50, color: AppColors.primary)
                  : null,
            ),
            const SizedBox(height: 10),
            Text(
              profileProvider.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              profileProvider.email,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _editProfilePicture,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Change Profile Picture',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 30),
            _buildMenuOption(Icons.person, 'Personal Info', _navigateToPersonalInfo),
            _buildMenuOption(Icons.lock_person, 'Change Password', _navigateToChangePass),
            _buildMenuOption(Icons.article, 'Terms & Conditions', _navigateToTermsAndConditions),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _showLogoutDialog,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, color: Colors.red),
                  SizedBox(width: 10),
                  Text(
                    'Log out',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: "Logout",
        content: "Are you sure you want to logout?",
        confirmText: "Logout",
        cancelText: "Cancel",
        onConfirm: _logout,
      ),
    );
  }

  Widget _buildMenuOption(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: onTap,
    );
  }
}
