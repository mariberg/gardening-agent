import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// Formats the header date as "Today · Wed 23 Apr".
String formatHeaderDate(DateTime date) {
  final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
  final monthName = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1];
  return 'Today · $dayName ${date.day} $monthName';
}

/// Dark green header with date label, "Watering" title, and "Select all" button.
class WateringHeader extends StatelessWidget {
  const WateringHeader({
    super.key,
    required this.allSelected,
    required this.onSelectAll,
    DateTime? date,
  }) : _date = date;

  /// Whether all pending plants are currently selected.
  final bool allSelected;

  /// Called when the user taps the "Select all" button.
  final VoidCallback onSelectAll;

  /// Optional date override (defaults to DateTime.now()).
  final DateTime? _date;

  @override
  Widget build(BuildContext context) {
    final displayDate = _date ?? DateTime.now();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      color: AppColors.darkGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatHeaderDate(displayDate),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.heroSubtitle,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Watering',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.heroText,
                ),
              ),
              _SelectAllButton(
                isActive: allSelected,
                onTap: onSelectAll,
              ),
            ],
          ),
        ],
      ),
    );
  }
}


/// The "Select all" button with default and active visual states.
class _SelectAllButton extends StatelessWidget {
  const _SelectAllButton({
    required this.isActive,
    required this.onTap,
  });

  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = isActive
        ? const Color.fromRGBO(127, 184, 106, 0.25)
        : const Color.fromRGBO(255, 255, 255, 0.08);

    final borderColor = isActive
        ? AppColors.heroSubtitle
        : const Color.fromRGBO(255, 255, 255, 0.15);

    final textColor = isActive
        ? AppColors.filterChipActiveText
        : AppColors.heroSubtitle;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'Select all',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
