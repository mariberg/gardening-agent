import 'package:flutter/material.dart';
import '../models/action_log_entry.dart';
import '../theme/app_colors.dart';

/// A single row in the care timeline, showing a coloured dot, vertical
/// connector line, date, action title, notes, tag chip, and logged-by label.
///
/// Used in both [OverviewTab] and [HistoryTab].
class TimelineEntry extends StatelessWidget {
  const TimelineEntry({
    super.key,
    required this.entry,
    this.isLast = false,
  });

  /// The action log entry to render.
  final ActionLogEntry entry;

  /// When `true` the vertical connector below the dot is hidden.
  final bool isLast;

  // ── Dot colour per action type ────────────────────────────────────
  static Color dotColor(ActionType type) {
    return switch (type) {
      ActionType.watered => AppColors.statusGreen,
      ActionType.pruned => AppColors.statusAmber,
      ActionType.fertilised => AppColors.blueInfo,
      ActionType.issueFound => AppColors.statusRed,
      ActionType.repotted => AppColors.statusGreen,
      ActionType.other => Colors.grey,
    };
  }

  // ── Tag chip colours per action type ──────────────────────────────
  static (Color bg, Color text) tagChipColors(ActionType type) {
    return switch (type) {
      ActionType.watered => (AppColors.chipGreenBg, AppColors.chipGreenText),
      ActionType.pruned => (AppColors.chipAmberBg, AppColors.chipAmberText),
      ActionType.fertilised => (AppColors.chipBlueBg, AppColors.chipBlueText),
      ActionType.issueFound => (AppColors.redBg, AppColors.redText),
      ActionType.repotted => (AppColors.chipGreenBg, AppColors.chipGreenText),
      ActionType.other => (const Color(0xFFF0F0F0), Colors.black54),
    };
  }

  // ── Human-readable action label ───────────────────────────────────
  static String actionLabel(ActionType type) {
    return switch (type) {
      ActionType.watered => 'Watered',
      ActionType.pruned => 'Pruned',
      ActionType.fertilised => 'Fertilised',
      ActionType.issueFound => 'Issue found',
      ActionType.repotted => 'Repotted',
      ActionType.other => 'Other',
    };
  }

  @override
  Widget build(BuildContext context) {
    final dot = dotColor(entry.actionType);
    final (chipBg, chipText) = tagChipColors(entry.actionType);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Timeline indicator (dot + line) ──────────────────────
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: dot,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // ── Content ─────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date
                  Text(
                    _formatDate(entry.occurredAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Title
                  Text(
                    entry.title ?? actionLabel(entry.actionType),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.deepGreenText,
                    ),
                  ),
                  // Notes
                  if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry.notes!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Tag chip + logged-by + thumbnail indicator
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Colour-coded tag chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 2,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: chipBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          actionLabel(entry.actionType),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: chipText,
                          ),
                        ),
                      ),
                      // User / agent label
                      Text(
                        entry.loggedBy == LoggedBy.user
                            ? 'Logged by you'
                            : 'Logged by AI',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      // Thumbnail indicator
                      if (entry.imageRefs.isNotEmpty)
                        Icon(
                          Icons.image_outlined,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Formats a [DateTime] as "d MMM yyyy" (e.g. "5 Jun 2025").
  static String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
