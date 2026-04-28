import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// Section header displaying "Plants ({count})" on the left
/// and a "+ Add" link on the right.
class PlantsSectionHeader extends StatelessWidget {
  const PlantsSectionHeader({super.key, required this.count});

  /// Total number of plants to display in the header.
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Plants ($count)',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: const Text(
              '+ Add',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.activeGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
