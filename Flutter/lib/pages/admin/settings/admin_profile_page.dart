import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skripsi/constants/app_colors.dart';
import 'package:skripsi/providers/profile_provider.dart';
import 'package:skripsi/utility/lower_case_text_formatter.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool isEditing = false;
  Uint8List? _selectedImage;
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController positionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    profileProvider.loadProfile().then((_) {
      setState(() {
        nameController.text = profileProvider.name;
        emailController.text = profileProvider.email;
        positionController.text = profileProvider.position;
      });
    }).catchError((error) {
      debugPrint("Error loading profile: \$error");
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
  
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    await profileProvider.updateProfile(
      nameController.text,
      positionController.text,
      emailController.text.toLowerCase(),
      adminImage: _selectedImage,
    );
    setState(() {
      isEditing = false;
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    positionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text("Admin Profile"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 80,
                  backgroundColor: AppColors.background1,
                  backgroundImage: _selectedImage != null
                      ? MemoryImage(_selectedImage!)
                      : (profileProvider.profileImage.isNotEmpty ? NetworkImage(profileProvider.profileImage) : null),
                  child: (_selectedImage == null && profileProvider.profileImage.isEmpty)
                      ? const Icon(Icons.person, size: 90, color: AppColors.text1)
                      : null,
                ),
                const SizedBox(height: 20),
                if (isEditing) ...[_buildImageButtons(profileProvider)],
                const SizedBox(height: 20),
                _buildProfileField("Full Name", nameController),
                _buildProfileField("Email", emailController),
                _buildProfileField("position", positionController),
                const SizedBox(height: 20),
                isEditing ? _buildEditModeButtons() : _buildEditButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageButtons(ProfileProvider profileProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: () async {
            final Uint8List? imageBytes = await profileProvider.selectImage();
            if (imageBytes != null) {
              setState(() {
                _selectedImage = imageBytes;
              });
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          icon: const Icon(Icons.camera_alt, color: AppColors.text1),
          label: const Text("Change Picture", style: TextStyle(color: AppColors.text1)),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: () async {
            try {
              await profileProvider.removeProfileImage();
              setState(() {
                _selectedImage = null;
              });
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Failed to remove profile image")),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.cancel),
          icon: const Icon(Icons.delete, color: AppColors.text1),
          label: const Text("Remove", style: TextStyle(color: AppColors.text1)),
        ),
      ],
    );
  }

  Widget _buildProfileField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.text2,
              )),
          const SizedBox(height: 5),
          TextFormField(
            controller: controller,
            enabled: isEditing,
            inputFormatters: label == "Email" ? [LowerCaseTextFormatter()] : null,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "$label is required";
              }
              if (label == "Email" && !RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(value)) {
                return "The email address is badly formatted";
              }
              return null;
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: !isEditing,
              fillColor: isEditing ? AppColors.background1 : AppColors.background2,
              contentPadding: const EdgeInsets.symmetric(horizontal: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditModeButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: _saveProfile,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text(
            "Save",
            style: TextStyle(color: AppColors.text1),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () {
            final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
            setState(() {
              isEditing = false;
              _selectedImage = null;
              nameController.text = profileProvider.name;
              emailController.text = profileProvider.email;
              positionController.text = profileProvider.position;
            });
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.cancel),
          child: const Text(
            "Cancel",
            style: TextStyle(color: AppColors.text1),
          ),
        ),
      ],
    );
  }

  Widget _buildEditButton() {
    return ElevatedButton(
      onPressed: () => setState(() => isEditing = true),
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
      child: const Text(
        "Edit Profile",
        style: TextStyle(color: AppColors.text1),
      ),
    );
  }
}
