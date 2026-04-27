import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A green-tinted card displaying AI-generated personalised advice for a plant.
///
/// Used at the top of the [OverviewTab] to show the plant's AI insight text.
class AIInsightCard extends StatelessWidget {
  const AIInsightCard({
    super.key,
    required this.insightText,
  });

  /// The personalised AI insight text to display.
  final String insightText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        border: Border.all(color: AppColors.greenBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI badge row
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: AppColors.activeGreen,
              ),
              const SizedBox(width: 6),
              Text(
                'AI personalised insight',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.activeGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Insight body
          Text(
            insightText,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
