import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// Sticky bar displayed below the header when one or more plants are selected.
/// Shows "{N} selected" text and a "Mark watered" button.
class BulkActionBar extends StatelessWidget {
  const BulkActionBar({
    super.key,
    required this.selectedCount,
    required this.onMarkWatered,
  });

  /// Number of currently selected plants.
  final int selectedCount;

  /// Called when the user taps the "Mark watered" button.
  final VoidCallback onMarkWatered;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        border: Border(
          bottom: BorderSide(color: AppColors.greenBorder, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$selectedCount selected',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.deepGreenText,
            ),
          ),
          GestureDetector(
            onTap: onMarkWatered,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.activeGreen,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Mark watered',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
