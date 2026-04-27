import 'package:flutter/material.dart';
import '../models/care_instruction.dart';
import '../theme/app_colors.dart';

/// A card displaying a care instruction with title, body, source label,
/// and an optional "AI verified" badge with confidence percentage.
///
/// Used in both [OverviewTab] and [CareTab].
class CareInstructionCard extends StatelessWidget {
  const CareInstructionCard({
    super.key,
    required this.instruction,
  });

  /// The care instruction to display.
  final CareInstruction instruction;

  /// Human-readable label for a [SourceType].
  static String sourceLabel(SourceType type) {
    return switch (type) {
      SourceType.rhs => 'RHS',
      SourceType.forum => 'Forum',
      SourceType.book => 'Book',
      SourceType.other => 'Other',
    };
  }

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
          // Title
          Text(
            instruction.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.deepGreenText,
            ),
          ),
          const SizedBox(height: 6),
          // Body
          Text(
            instruction.body,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          // Source label + AI verified badge
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Source type chip
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 2,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.greenBorder),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  sourceLabel(instruction.sourceType),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepGreenText,
                  ),
                ),
              ),
              // AI verified badge
              if (instruction.aiVerified)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 2,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.activeGreen,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        instruction.aiConfidence != null
                            ? 'AI verified · ${(instruction.aiConfidence! * 100).round()}%'
                            : 'AI verified',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
