import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A rounded pill chip with active/inactive states used to filter content
/// in the Photos and Care tabs.
///
/// Named `AppFilterChip` to avoid collision with Flutter's built-in
/// [FilterChip] widget.
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  /// The text shown inside the chip.
  final String label;

  /// Whether the chip is in the active (selected) state.
  final bool isSelected;

  /// Called when the chip is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.filterChipActiveBg : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? AppColors.filterChipActiveBg
                : Colors.grey.shade400,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected
                ? AppColors.filterChipActiveText
                : Colors.black54,
          ),
        ),
      ),
    );
  }
}
