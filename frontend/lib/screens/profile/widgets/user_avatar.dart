import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../profile_utils.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: const BoxDecoration(
        color: AppColors.heroCardOverlay,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        avatarInitial(name),
        style: const TextStyle(
          fontSize: 28,
          color: AppColors.heroText,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
