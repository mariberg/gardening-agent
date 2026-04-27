import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Colour variant for [StatusChip].
enum StatusChipVariant {
  /// Green – used for plant status (e.g. "Thriving").
  green,

  /// Amber – used for watering info (e.g. "Water tomorrow").
  amber,

  /// Blue – used for sun requirements (e.g. "Full sun").
  blue,

  /// Red – used for alert status (e.g. "Mildew alert").
  red,
}

/// A small rounded badge that displays a short [label] with a coloured
/// background, border, and text determined by [variant].
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.variant,
  });

  /// The text shown inside the chip.
  final String label;

  /// Determines the background, border, and text colours.
  final StatusChipVariant variant;

  @override
  Widget build(BuildContext context) {
    final (bg, border, text) = _colours(variant);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }

  static (Color, Color, Color) _colours(StatusChipVariant variant) {
    return switch (variant) {
      StatusChipVariant.green => (
          AppColors.chipGreenBg,
          AppColors.chipGreenBorder,
          AppColors.chipGreenText,
        ),
      StatusChipVariant.amber => (
          AppColors.chipAmberBg,
          AppColors.chipAmberBorder,
          AppColors.chipAmberText,
        ),
      StatusChipVariant.blue => (
          AppColors.chipBlueBg,
          AppColors.chipBlueBorder,
          AppColors.chipBlueText,
        ),
      StatusChipVariant.red => (
          AppColors.redBg,
          AppColors.redBorder,
          AppColors.redText,
        ),
    };
  }
}
