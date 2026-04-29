import 'package:flutter/material.dart';
import '../../../models/plant_instance.dart';
import '../../../theme/app_colors.dart';
import 'check_circle.dart';

/// A single plant row in the watering list.
///
/// Displays a [CheckCircle], the plant nickname, a subtitle with
/// overdue/due info, and a status badge. Visual treatment varies
/// based on selection and done state.
class WateringPlantItem extends StatelessWidget {
  const WateringPlantItem({
    super.key,
    required this.plant,
    required this.isSelected,
    required this.isDone,
    required this.onTap,
  });

  /// The plant instance to display.
  final PlantInstance plant;

  /// Whether this item is currently selected.
  final bool isSelected;

  /// Whether this plant has already been watered today.
  final bool isDone;

  /// Called when the user taps this item. Null-safe: ignored when done.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final checkState = isDone
        ? CheckCircleState.done
        : isSelected
            ? CheckCircleState.selected
            : CheckCircleState.empty;

    final bgColor = (!isDone && isSelected)
        ? AppColors.lightGreen
        : Colors.transparent;

    return GestureDetector(
      onTap: isDone ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: bgColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CheckCircle(state: checkState),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.nickname,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone ? Colors.grey : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDone ? Colors.grey : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            _buildBadge(),
          ],
        ),
      ),
    );
  }

  String get _subtitle {
    if (isDone) return 'Watered · just now';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final wateringDate = plant.nextWateringDate;
    if (wateringDate == null) return 'Due today';
    final dateOnly = DateTime(wateringDate.year, wateringDate.month, wateringDate.day);
    final daysOverdue = today.difference(dateOnly).inDays;
    if (daysOverdue <= 0) return 'Due today';
    return '$daysOverdue day${daysOverdue > 1 ? 's' : ''} overdue';
  }

  Widget _buildBadge() {
    if (isDone) {
      return _badge('Done', AppColors.activeGreen);
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final wateringDate = plant.nextWateringDate;
    if (wateringDate == null) {
      return _badge('Due', AppColors.activeGreen);
    }
    final dateOnly = DateTime(wateringDate.year, wateringDate.month, wateringDate.day);
    if (dateOnly.isBefore(today)) {
      return _badge('Overdue', AppColors.statusRed);
    }
    return _badge('Due', AppColors.activeGreen);
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
