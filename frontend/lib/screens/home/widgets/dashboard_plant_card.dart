import 'package:flutter/material.dart';

import '../../../models/plant_instance.dart';
import '../../../theme/app_colors.dart';

/// Individual plant card displaying emoji, nickname, species name,
/// and a colour-coded status dot with label.
///
/// Tapping the card navigates to the plant detail screen.
class DashboardPlantCard extends StatelessWidget {
  const DashboardPlantCard({super.key, required this.plant});

  final PlantInstance plant;

  Color _statusColor(PlantStatus status) {
    switch (status) {
      case PlantStatus.thriving:
        return AppColors.statusGreen;
      case PlantStatus.needsAttention:
        return AppColors.statusAmber;
      case PlantStatus.alert:
        return AppColors.statusRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          '/plant-detail',
          arguments: {'plantInstanceId': plant.instanceId},
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plant.emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              plant.nickname,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              plant.speciesCommonName,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _statusColor(plant.status),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    plant.statusLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
