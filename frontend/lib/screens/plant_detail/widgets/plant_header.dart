import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/plant_instance.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/status_chip.dart';

/// The dark-green header displayed inside the [SliverAppBar] flexibleSpace.
///
/// Shows the plant emoji, nickname, planted date, garden location, and three
/// [StatusChip] widgets for status, next watering, and sun requirements.
class PlantHeader extends StatelessWidget {
  const PlantHeader({super.key, required this.plant});

  /// The plant instance whose details are rendered.
  final PlantInstance plant;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkGreen,
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji + nickname row
          Text(
            '${plant.emoji} ${plant.nickname}',
            style: const TextStyle(
              color: AppColors.heroText,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          // Planted date + garden location
          Text(
            'Planted ${DateFormat('d MMM yyyy').format(plant.plantedAt)}  ·  ${plant.gardenLocation}',
            style: const TextStyle(
              color: AppColors.heroSubtitle,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          // Status chips row
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StatusChip(
                label: plant.statusLabel,
                variant: _statusVariant(plant.status),
              ),
              if (plant.nextWateringDate != null)
                StatusChip(
                  label: _wateringLabel(plant.nextWateringDate!),
                  variant: StatusChipVariant.amber,
                ),
              StatusChip(
                label: plant.sunRequirement,
                variant: StatusChipVariant.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Maps [PlantStatus] to the appropriate [StatusChipVariant].
  static StatusChipVariant _statusVariant(PlantStatus status) {
    return switch (status) {
      PlantStatus.thriving => StatusChipVariant.green,
      PlantStatus.needsAttention => StatusChipVariant.amber,
      PlantStatus.alert => StatusChipVariant.red,
    };
  }

  /// Produces a human-readable watering label such as "Water tomorrow" or
  /// "Water in 3 days".
  static String _wateringLabel(DateTime nextWatering) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(
      nextWatering.year,
      nextWatering.month,
      nextWatering.day,
    );
    final diff = target.difference(today).inDays;

    if (diff <= 0) return 'Water today';
    if (diff == 1) return 'Water tomorrow';
    return 'Water in $diff days';
  }
}
