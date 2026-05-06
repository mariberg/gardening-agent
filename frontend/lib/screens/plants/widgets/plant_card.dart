import 'package:flutter/material.dart';

import 'package:garden_app/models/plant_instance.dart';
import 'package:garden_app/screens/plants/widgets/plant_status_indicator.dart';

class PlantCard extends StatelessWidget {
  const PlantCard({
    super.key,
    required this.plant,
    required this.onTap,
  });

  final PlantInstance plant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
            Text(plant.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              plant.nickname,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              plant.speciesCommonName,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              plant.gardenLocation,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            PlantStatusIndicator(
              status: plant.status,
              label: plant.statusLabel,
            ),
          ],
        ),
      ),
    );
  }
}
