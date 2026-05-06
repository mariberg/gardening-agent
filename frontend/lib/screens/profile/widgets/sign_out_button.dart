import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// A full-width button with centre-aligned "Sign Out" text styled in red.
///
/// Used at the bottom of the profile screen to trigger the sign-out flow.
class SignOutButton extends StatelessWidget {
  const SignOutButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        child: const Text(
          'Sign Out',
          style: TextStyle(
            color: AppColors.statusRed,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
