import 'package:flutter/material.dart';

import 'package:garden_app/models/plant_instance.dart';
import 'package:garden_app/theme/app_colors.dart';

class PlantStatusIndicator extends StatelessWidget {
  const PlantStatusIndicator({
    super.key,
    required this.status,
    required this.label,
  });

  final PlantStatus status;
  final String label;

  Color get _dotColor => switch (status) {
    PlantStatus.thriving => AppColors.statusGreen,
    PlantStatus.needsAttention => AppColors.statusAmber,
    PlantStatus.alert => AppColors.statusRed,
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
