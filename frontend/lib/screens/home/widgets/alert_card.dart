import 'package:flutter/material.dart';

import '../../../models/action_log_entry.dart';
import '../../../theme/app_colors.dart';

/// An amber alert card displaying an unresolved plant issue.
/// The parent widget handles visibility — this widget simply renders
/// when given an [ActionLogEntry] and the affected plant's nickname.
class AlertCard extends StatelessWidget {
  const AlertCard({
    super.key,
    required this.entry,
    required this.plantNickname,
  });

  /// The unresolved issue log entry to display.
  final ActionLogEntry entry;

  /// The nickname of the affected plant.
  final String plantNickname;

  @override
  Widget build(BuildContext context) {
    final daysSinceLogged = DateTime.now().difference(entry.occurredAt).inDays;
    final issueType = entry.title ?? entry.actionType.name;
    final recommendation =
        entry.notes ?? 'Check on this plant and resolve the issue.';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.amberBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.statusAmber),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.statusAmber,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$plantNickname · $issueType',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$daysSinceLogged day${daysSinceLogged == 1 ? '' : 's'} ago',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  recommendation,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
