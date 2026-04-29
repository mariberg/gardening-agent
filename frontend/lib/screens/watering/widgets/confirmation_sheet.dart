import 'package:flutter/material.dart';
import '../../../models/plant_instance.dart';
import '../../../theme/app_colors.dart';

/// A lightweight bottom sheet that summarises the selected plants before
/// the user commits the bulk watering action.
///
/// Shows the title "Mark {N} plants as watered?", lists each selected plant
/// with a coloured dot, nickname, and status badge, and provides a confirm
/// button with contextual text.
class ConfirmationSheet extends StatelessWidget {
  const ConfirmationSheet({
    super.key,
    required this.selectedPlants,
    required this.onConfirm,
  });

  /// The plants the user has selected to mark as watered.
  final List<PlantInstance> selectedPlants;

  /// Called when the user taps the confirm button.
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final count = selectedPlants.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            'Mark $count plants as watered?',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.deepGreenText,
            ),
          ),
          const SizedBox(height: 16),
          // Plant list
          ...selectedPlants.map((plant) => _buildPlantRow(plant)),
          const SizedBox(height: 20),
          // Confirm button
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () {
                onConfirm();
                Navigator.of(context).pop();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.activeGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  _confirmButtonText(count),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantRow(PlantInstance plant) {
    final badgeInfo = _badgeForPlant(plant);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Coloured dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: badgeInfo.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          // Nickname
          Expanded(
            child: Text(
              plant.nickname,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeInfo.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              badgeInfo.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: badgeInfo.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Returns the contextual confirm button text based on the count.
  static String _confirmButtonText(int count) {
    if (count == 1) return 'Confirm — watered it';
    if (count == 2) return 'Confirm — watered both';
    return 'Confirm — watered all $count';
  }

  /// Determines the badge label and colour for a plant based on its
  /// nextWateringDate relative to today.
  _BadgeInfo _badgeForPlant(PlantInstance plant) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final wateringDate = plant.nextWateringDate;

    if (wateringDate == null) {
      return _BadgeInfo('Due today', AppColors.activeGreen);
    }

    final dateOnly = DateTime(
      wateringDate.year,
      wateringDate.month,
      wateringDate.day,
    );

    if (dateOnly.isBefore(today)) {
      return _BadgeInfo('Was overdue', AppColors.statusRed);
    }
    return _BadgeInfo('Due today', AppColors.activeGreen);
  }
}

/// Simple data holder for badge label and colour.
class _BadgeInfo {
  const _BadgeInfo(this.label, this.color);
  final String label;
  final Color color;
}
