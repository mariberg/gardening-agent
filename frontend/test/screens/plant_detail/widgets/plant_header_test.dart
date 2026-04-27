import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden_app/models/plant_instance.dart';
import 'package:garden_app/screens/plant_detail/widgets/plant_header.dart';
import 'package:garden_app/theme/app_colors.dart';
import 'package:garden_app/widgets/status_chip.dart';

void main() {
  PlantInstance makePlant({
    PlantStatus status = PlantStatus.thriving,
    String statusLabel = 'Thriving',
    DateTime? nextWateringDate,
  }) {
    return PlantInstance(
      instanceId: 'plant-001',
      speciesId: 'species-tomato',
      nickname: 'Cherry Tomato',
      emoji: '🍅',
      gardenLocation: 'Raised bed A',
      plantedAt: DateTime(2025, 3, 15),
      status: status,
      statusLabel: statusLabel,
      nextWateringDate: nextWateringDate ?? DateTime.now().add(const Duration(days: 1)),
      sunRequirement: 'Full sun',
      speciesCommonName: 'Cherry Tomato',
      speciesLatinName: 'Solanum lycopersicum',
    );
  }

  Widget buildHeader(PlantInstance plant) {
    return MaterialApp(
      home: Scaffold(body: PlantHeader(plant: plant)),
    );
  }

  group('PlantHeader', () {
    testWidgets('displays emoji and nickname', (tester) async {
      await tester.pumpWidget(buildHeader(makePlant()));
      expect(find.textContaining('🍅'), findsOneWidget);
      expect(find.textContaining('Cherry Tomato'), findsOneWidget);
    });

    testWidgets('displays planted date and garden location', (tester) async {
      await tester.pumpWidget(buildHeader(makePlant()));
      expect(find.textContaining('Planted 15 Mar 2025'), findsOneWidget);
      expect(find.textContaining('Raised bed A'), findsOneWidget);
    });

    testWidgets('renders three StatusChip widgets', (tester) async {
      await tester.pumpWidget(buildHeader(makePlant()));
      expect(find.byType(StatusChip), findsNWidgets(3));
    });

    testWidgets('status chip shows status label', (tester) async {
      await tester.pumpWidget(buildHeader(makePlant()));
      expect(find.text('Thriving'), findsOneWidget);
    });

    testWidgets('sun requirement chip is present', (tester) async {
      await tester.pumpWidget(buildHeader(makePlant()));
      expect(find.text('Full sun'), findsOneWidget);
    });

    testWidgets('watering chip shows "Water tomorrow" for +1 day', (tester) async {
      final plant = makePlant(
        nextWateringDate: DateTime.now().add(const Duration(days: 1)),
      );
      await tester.pumpWidget(buildHeader(plant));
      expect(find.text('Water tomorrow'), findsOneWidget);
    });

    testWidgets('watering chip shows "Water today" for today', (tester) async {
      final plant = makePlant(nextWateringDate: DateTime.now());
      await tester.pumpWidget(buildHeader(plant));
      expect(find.text('Water today'), findsOneWidget);
    });

    testWidgets('has dark green background', (tester) async {
      await tester.pumpWidget(buildHeader(makePlant()));
      final container = tester.widget<Container>(
        find.byType(Container).first,
      );
      expect(container.color, AppColors.darkGreen);
    });

    testWidgets('thriving status maps to green chip variant', (tester) async {
      await tester.pumpWidget(buildHeader(makePlant()));
      final chips = tester.widgetList<StatusChip>(find.byType(StatusChip)).toList();
      final statusChip = chips.firstWhere((c) => c.label == 'Thriving');
      expect(statusChip.variant, StatusChipVariant.green);
    });

    testWidgets('needsAttention status maps to amber chip variant', (tester) async {
      final plant = makePlant(
        status: PlantStatus.needsAttention,
        statusLabel: 'Needs attention',
      );
      await tester.pumpWidget(buildHeader(plant));
      final chips = tester.widgetList<StatusChip>(find.byType(StatusChip)).toList();
      final statusChip = chips.firstWhere((c) => c.label == 'Needs attention');
      expect(statusChip.variant, StatusChipVariant.amber);
    });

    testWidgets('alert status maps to red chip variant', (tester) async {
      final plant = makePlant(
        status: PlantStatus.alert,
        statusLabel: 'Mildew alert',
      );
      await tester.pumpWidget(buildHeader(plant));
      final chips = tester.widgetList<StatusChip>(find.byType(StatusChip)).toList();
      final statusChip = chips.firstWhere((c) => c.label == 'Mildew alert');
      expect(statusChip.variant, StatusChipVariant.red);
    });

    testWidgets('omits watering chip when nextWateringDate is null', (tester) async {
      final noWaterPlant = PlantInstance(
        instanceId: 'plant-x',
        speciesId: 'species-x',
        nickname: 'Test',
        emoji: '🌱',
        gardenLocation: 'Pot',
        plantedAt: DateTime(2025, 1, 1),
        status: PlantStatus.thriving,
        statusLabel: 'Thriving',
        nextWateringDate: null,
        sunRequirement: 'Full sun',
        speciesCommonName: 'Test',
        speciesLatinName: 'Testus',
      );
      await tester.pumpWidget(buildHeader(noWaterPlant));
      // Only 2 chips: status + sun
      expect(find.byType(StatusChip), findsNWidgets(2));
    });
  });
}
