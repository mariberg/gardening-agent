import 'package:flutter/material.dart';

import '../../../models/dashboard_summary.dart';
import '../../../theme/app_colors.dart';

/// A small chip that displays a single weather data point (e.g. "18°C today").
///
/// Uses a semi-transparent background with [AppColors.heroMuted] text, designed
/// to sit inside the [AiSummaryCard] within the dark-green dashboard header.
class WeatherChipWidget extends StatelessWidget {
  const WeatherChipWidget({super.key, required this.chip});

  /// The weather data to display.
  final WeatherChip chip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        chip.label,
        style: const TextStyle(
          color: AppColors.heroMuted,
          fontSize: 12,
        ),
      ),
    );
  }
}
