import 'package:flutter/material.dart';

import '../../../models/user_profile.dart';
import '../../../theme/app_colors.dart';
import 'user_avatar.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.darkGreen,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          UserAvatar(name: profile.name),
          const SizedBox(height: 16),
          Text(
            profile.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.heroText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile.email,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.heroSubtitle,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on,
                size: 16,
                color: AppColors.heroMuted,
              ),
              const SizedBox(width: 4),
              Text(
                profile.location,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.heroMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
