import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// Visual state for the [CheckCircle] widget.
enum CheckCircleState {
  /// No selection — empty circle with grey border.
  empty,

  /// Currently selected by the user — filled with activeGreen.
  selected,

  /// Already watered today — filled with lighter green.
  done,
}

/// A circular checkbox widget that renders differently based on [state].
///
/// | State    | Background              | Border              | Icon            |
/// |----------|-------------------------|---------------------|-----------------|
/// | Empty    | White/transparent       | Colors.grey.shade400| None            |
/// | Selected | AppColors.activeGreen   | Same                | White checkmark |
/// | Done     | Color(0xFF97C459)       | Same                | White checkmark |
class CheckCircle extends StatelessWidget {
  const CheckCircle({super.key, required this.state, this.size = 24.0});

  /// Controls the visual appearance of the circle.
  final CheckCircleState state;

  /// Diameter of the circle. Defaults to 24.
  final double size;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color border, bool showIcon) = switch (state) {
      CheckCircleState.empty => (
          Colors.white,
          Colors.grey.shade400,
          false,
        ),
      CheckCircleState.selected => (
          AppColors.activeGreen,
          AppColors.activeGreen,
          true,
        ),
      CheckCircleState.done => (
          const Color(0xFF97C459),
          const Color(0xFF97C459),
          true,
        ),
    };

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 2),
      ),
      child: showIcon
          ? Icon(Icons.check, size: size * 0.6, color: Colors.white)
          : null,
    );
  }
}
