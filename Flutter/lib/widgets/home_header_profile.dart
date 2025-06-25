import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skripsi/constants/app_colors.dart';
import 'package:skripsi/providers/profile_provider.dart';

class HomeHeaderProfile extends StatelessWidget {
  const HomeHeaderProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final profileImage = profileProvider.profileImage;
    final userName = profileProvider.name;
    final userPosition = profileProvider.position;

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundImage: profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
          child: profileImage.isEmpty
              ? const Icon(Icons.admin_panel_settings, size: 40, color: AppColors.primary)
              : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              userPosition,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }
}