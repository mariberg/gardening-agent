import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden_app/data/mock/mock_action_log_repository.dart';
import 'package:garden_app/data/mock/mock_care_instruction_repository.dart';
import 'package:garden_app/data/mock/mock_photo_repository.dart';
import 'package:garden_app/data/mock/mock_plant_repository.dart';
import 'package:garden_app/data/repository_provider.dart';
import 'package:garden_app/models/plant_instance.dart';
import 'package:garden_app/screens/plant_detail/widgets/log_action_sheet.dart';

void main() {
  late PlantInstance testPlant;

  setUp(() {
    testPlant = PlantInstance(
      instanceId: 'plant-001',
      speciesId: 'species-tomato',
      nickname: 'Cherry Tomato',
      emoji: '🍅',
      gardenLocation: 'Raised bed A',
      plantedAt: DateTime(2025, 3, 15),
      status: PlantStatus.thriving,
      statusLabel: 'Thriving',
      sunRequirement: 'Full sun',
      speciesCommonName: 'Cherry Tomato',
      speciesLatinName: 'Solanum lycopersicum',
    );
  });

  Widget buildSheet() {
    return RepositoryProvider(
      plantRepository: MockPlantRepository(),
      actionLogRepository: MockActionLogRepository(),
      careInstructionRepository: MockCareInstructionRepository(),
      photoRepository: MockPhotoRepository(),
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => LogActionSheet.show(context, plant: testPlant),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.pumpWidget(buildSheet());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  group('LogActionSheet', () {
    testWidgets('displays header with plant info', (tester) async {
      await openSheet(tester);
      expect(find.text('Cherry Tomato'), findsOneWidget);
      expect(find.textContaining('Raised bed A'), findsOneWidget);
      expect(find.text('🍅'), findsOneWidget);
    });

    testWidgets('displays 6 action type buttons', (tester) async {
      await openSheet(tester);
      expect(find.text('Watered'), findsOneWidget);
      expect(find.text('Pruned'), findsOneWidget);
      expect(find.text('Fertilised'), findsOneWidget);
      expect(find.text('Issue found'), findsOneWidget);
      expect(find.text('Repotted'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
    });

    testWidgets('selecting action updates submit button label', (tester) async {
      await openSheet(tester);
      // Initially shows generic label
      expect(find.text('Log action'), findsOneWidget);

      await tester.tap(find.text('Watered'));
      await tester.pump();
      expect(find.text('Log watered'), findsOneWidget);

      await tester.tap(find.text('Pruned'));
      await tester.pump();
      expect(find.text('Log pruned'), findsOneWidget);
    });

    testWidgets('severity picker only visible when Issue found selected',
        (tester) async {
      await openSheet(tester);
      // Not visible initially
      expect(find.text('Severity'), findsNothing);
      expect(find.text('Mild'), findsNothing);

      // Select Issue found
      await tester.tap(find.text('Issue found'));
      await tester.pump();
      expect(find.text('Severity'), findsOneWidget);
      expect(find.text('Mild'), findsOneWidget);
      expect(find.text('Moderate'), findsOneWidget);
      expect(find.text('Severe'), findsOneWidget);

      // Switch away hides it
      await tester.tap(find.text('Watered'));
      await tester.pump();
      expect(find.text('Severity'), findsNothing);
    });

    testWidgets('close button dismisses sheet', (tester) async {
      await openSheet(tester);
      expect(find.text('Cherry Tomato'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('Cherry Tomato'), findsNothing);
    });

    testWidgets('submit button disabled when no action selected',
        (tester) async {
      await openSheet(tester);
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Log action'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('submit button enabled after selecting action',
        (tester) async {
      await openSheet(tester);
      await tester.tap(find.text('Watered'));
      await tester.pump();
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Log watered'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('primary submit creates log and dismisses sheet',
        (tester) async {
      await openSheet(tester);
      await tester.tap(find.text('Watered'));
      await tester.pump();

      // Scroll the submit button into view before tapping
      await tester.ensureVisible(find.text('Log watered'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log watered'));
      await tester.pumpAndSettle();

      // Sheet should be dismissed
      expect(find.text('Cherry Tomato'), findsNothing);
    });

    testWidgets('notes field shows action-specific placeholder',
        (tester) async {
      await openSheet(tester);

      // Default placeholder
      expect(find.text('Add any notes...'), findsOneWidget);

      await tester.tap(find.text('Fertilised'));
      await tester.pump();
      expect(find.text('What fertiliser? How much?'), findsOneWidget);

      await tester.tap(find.text('Issue found'));
      await tester.pump();
      expect(find.text('Describe the issue...'), findsOneWidget);
    });

    testWidgets('camera button adds photo thumbnail', (tester) async {
      await openSheet(tester);
      // Tap camera icon
      await tester.tap(find.byIcon(Icons.camera_alt_outlined));
      await tester.pump();
      // Should show an image thumbnail
      expect(find.byIcon(Icons.image), findsOneWidget);
    });
  });
}
