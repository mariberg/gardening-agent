import 'package:flutter/material.dart';

import '../../../models/dashboard_summary.dart';
import '../../../theme/app_colors.dart';
import 'ai_summary_card.dart';

/// Dark green header section displaying the "YOUR GARDEN" label,
/// a time-aware greeting, and the [AiSummaryCard].
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key, required this.summary});

  /// Dashboard data used for the greeting name and AI card content.
  final DashboardSummary summary;

  String _greeting(String name) {
    final hour = DateTime.now().hour;
    final period =
        hour < 12 ? 'morning' : (hour < 17 ? 'afternoon' : 'evening');
    return 'Good $period, $name';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
      color: AppColors.darkGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR GARDEN',
            style: TextStyle(
              color: AppColors.heroSubtitle,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _greeting(summary.userName),
            style: const TextStyle(
              color: AppColors.heroText,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          AiSummaryCard(
            summaryText: summary.aiSummaryText,
            weatherChips: summary.weatherChips,
          ),
        ],
      ),
    );
  }
}
