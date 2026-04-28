import 'package:flutter/material.dart';

import '../../../models/plant_instance.dart';
import 'dashboard_plant_card.dart';

/// Two-column grid that renders a [DashboardPlantCard] for each plant instance.
///
/// Uses [shrinkWrap] and [NeverScrollableScrollPhysics] so it can live
/// inside a parent [SingleChildScrollView] without conflicting scroll contexts.
class PlantGrid extends StatelessWidget {
  const PlantGrid({super.key, required this.plants});

  final List<PlantInstance> plants;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: plants
            .map((plant) => DashboardPlantCard(plant: plant))
            .toList(),
      ),
    );
  }
}
