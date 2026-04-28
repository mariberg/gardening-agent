import 'package:flutter/material.dart';

import '../../../models/dashboard_summary.dart';
import '../../../theme/app_colors.dart';
import 'weather_chip.dart';

/// A semi-transparent card displaying an AI-generated garden summary with
/// weather chips. Sits inside the dark-green [DashboardHeader].
class AiSummaryCard extends StatelessWidget {
  const AiSummaryCard({
    super.key,
    required this.summaryText,
    required this.weatherChips,
  });

  /// The AI-generated summary text to display.
  final String summaryText;

  /// Weather data chips shown below the summary text.
  final List<WeatherChip> weatherChips;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.heroCardOverlay,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI summary badge row
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.heroSubtitle,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'AI summary',
                style: TextStyle(
                  color: AppColors.heroSubtitle,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Summary text
          Text(
            summaryText,
            style: const TextStyle(
              color: AppColors.heroMuted,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          // Weather chips row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: weatherChips
                .map((chip) => WeatherChipWidget(chip: chip))
                .toList(),
          ),
        ],
      ),
    );
  }
}
