import 'package:flutter/material.dart';

import '../../../models/garden_statistics.dart';
import '../../../theme/app_colors.dart';

/// A card displaying aggregate garden statistics in a 2x2 grid layout.
///
/// Shows total plants, active issues, total actions, and days active.
class GardenStatsCard extends StatelessWidget {
  const GardenStatsCard({
    super.key,
    required this.stats,
    required this.daysActive,
  });

  final GardenStatistics stats;
  final int daysActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greenBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  value: stats.totalPlants,
                  label: 'Plants',
                ),
              ),
              Expanded(
                child: _StatItem(
                  value: stats.activeIssues,
                  label: 'Issues',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  value: stats.totalActions,
                  label: 'Actions',
                ),
              ),
              Expanded(
                child: _StatItem(
                  value: daysActive,
                  label: 'Days Active',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
  });

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.activeGreen,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}
