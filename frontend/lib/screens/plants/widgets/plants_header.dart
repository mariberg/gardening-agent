import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// Dark green header displaying "My Plants" title and total plant count.
///
/// The [totalPlantCount] always reflects the total number of plants from the
/// repository, regardless of active filters or search terms.
class PlantsHeader extends StatelessWidget {
  const PlantsHeader({super.key, required this.totalPlantCount});

  final int totalPlantCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      color: AppColors.darkGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Plants',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.heroText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '($totalPlantCount plants)',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.heroSubtitle,
            ),
          ),
        ],
      ),
    );
  }
}
