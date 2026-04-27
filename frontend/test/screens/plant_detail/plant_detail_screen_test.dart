import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden_app/data/mock/mock_action_log_repository.dart';
import 'package:garden_app/data/mock/mock_care_instruction_repository.dart';
import 'package:garden_app/data/mock/mock_photo_repository.dart';
import 'package:garden_app/data/mock/mock_plant_repository.dart';
import 'package:garden_app/data/repository_provider.dart';
import 'package:garden_app/screens/plant_detail/plant_detail_screen.dart';
import 'package:garden_app/theme/app_colors.dart';

void main() {
  /// Wraps [PlantDetailScreen] with the required [RepositoryProvider] and
  /// [MaterialApp] so it can be pumped in widget tests.
  Widget buildScreen({String plantInstanceId = 'plant-001'}) {
    return RepositoryProvider(
      plantRepository: MockPlantRepository(),
      actionLogRepository: MockActionLogRepository(),
      careInstructionRepository: MockCareInstructionRepository(),
      photoRepository: MockPhotoRepository(),
      child: MaterialApp(
        home: PlantDetailScreen(plantInstanceId: plantInstanceId),
      ),
    );
  }

  group('PlantDetailScreen', () {
    testWidgets('shows loading indicator then renders content',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      // FutureBuilder starts in waiting state.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Let the future complete.
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('renders four tab labels', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // "Overview" appears in both the Tab and the placeholder, so at least 1.
      expect(find.text('Overview'), findsAtLeast(1));
      expect(find.text('History'), findsAtLeast(1));
      expect(find.text('Photos'), findsAtLeast(1));
      expect(find.text('Care'), findsAtLeast(1));

      // Verify exactly 4 Tab widgets exist.
      expect(find.byType(Tab), findsNWidgets(4));
    });

    testWidgets('defaults to Overview tab content', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // The real OverviewTab should render the AI insight card and care history header.
      expect(find.text('AI personalised insight'), findsOneWidget);
      expect(find.text('Care history'), findsOneWidget);
    });

    testWidgets('renders FAB with "+ Log action" label', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // The FAB label and the OverviewTab section link both say "+ Log action".
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.widgetWithText(FloatingActionButton, '+ Log action'),
          findsOneWidget);
    });

    testWidgets('SliverAppBar is pinned', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final sliverAppBar =
          tester.widget<SliverAppBar>(find.byType(SliverAppBar));
      expect(sliverAppBar.pinned, isTrue);
    });

    testWidgets('TabBar uses activeGreen indicator and label colours',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.labelColor, AppColors.activeGreen);
      expect(tabBar.unselectedLabelColor, Colors.grey);
      expect(tabBar.indicatorColor, AppColors.activeGreen);
      expect(tabBar.indicatorWeight, 2);
    });

    testWidgets('has a back button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('displays plant nickname in header', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Cherry Tomato mock has emoji 🍅 and nickname "Cherry Tomato".
      // The header shows it, and the AI insight text may also mention it.
      expect(find.textContaining('Cherry Tomato'), findsAtLeast(1));
    });

    testWidgets('uses DefaultTabController with 4 tabs', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final controller = DefaultTabController.of(
        tester.element(find.byType(TabBar)),
      );
      expect(controller.length, 4);
    });

    testWidgets('shows error state for invalid plant id', (tester) async {
      await tester.pumpWidget(buildScreen(plantInstanceId: 'nonexistent'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Error'), findsOneWidget);
    });
  });
}
