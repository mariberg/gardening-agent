import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// Displays "To water today" title with a contextual hint.
///
/// Hint logic:
/// - "tap to select" when [doneCount] == 0
/// - "{N} remaining" when some items are done
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.doneCount,
    required this.totalCount,
  });

  /// Number of plants already watered today.
  final int doneCount;

  /// Total number of plants due for watering today.
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'To water today',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.deepGreenText,
            ),
          ),
          Text(
            _hint(),
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String _hint() {
    if (doneCount == 0) return 'tap to select';
    final remaining = totalCount - doneCount;
    return '$remaining remaining';
  }
}
