import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden_app/models/action_log_entry.dart';
import 'package:garden_app/theme/app_colors.dart';
import 'package:garden_app/widgets/timeline_entry.dart';

ActionLogEntry _makeEntry({
  ActionType actionType = ActionType.watered,
  String? title,
  String? notes,
  LoggedBy loggedBy = LoggedBy.user,
  List<String> imageRefs = const [],
}) {
  return ActionLogEntry(
    actionId: 'a1',
    instanceId: 'p1',
    actionType: actionType,
    title: title,
    notes: notes,
    loggedBy: loggedBy,
    imageRefs: imageRefs,
    occurredAt: DateTime(2025, 6, 5),
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('TimelineEntry', () {
    testWidgets('renders date, title, and tag chip', (tester) async {
      final entry = _makeEntry(title: 'Morning watering');
      await tester.pumpWidget(_wrap(TimelineEntry(entry: entry)));

      expect(find.text('5 Jun 2025'), findsOneWidget);
      expect(find.text('Morning watering'), findsOneWidget);
      // Tag chip label
      expect(find.text('Watered'), findsOneWidget);
    });

    testWidgets('falls back to action label when title is null',
        (tester) async {
      final entry = _makeEntry(title: null);
      await tester.pumpWidget(_wrap(TimelineEntry(entry: entry)));

      // Title area should show the action label
      final titleFinder = find.text('Watered');
      // One for the title, one for the tag chip
      expect(titleFinder, findsNWidgets(2));
    });

    testWidgets('renders notes when present', (tester) async {
      final entry = _makeEntry(notes: 'Gave extra water');
      await tester.pumpWidget(_wrap(TimelineEntry(entry: entry)));

      expect(find.text('Gave extra water'), findsOneWidget);
    });

    testWidgets('hides notes when null', (tester) async {
      final entry = _makeEntry(notes: null);
      await tester.pumpWidget(_wrap(TimelineEntry(entry: entry)));

      // Only date, title, tag chip, and logged-by label should be present
      expect(find.text('Gave extra water'), findsNothing);
    });

    testWidgets('shows "Logged by you" for user entries', (tester) async {
      final entry = _makeEntry(loggedBy: LoggedBy.user);
      await tester.pumpWidget(_wrap(TimelineEntry(entry: entry)));

      expect(find.text('Logged by you'), findsOneWidget);
    });

    testWidgets('shows "Logged by AI" for agent entries', (tester) async {
      final entry = _makeEntry(loggedBy: LoggedBy.agent);
      await tester.pumpWidget(_wrap(TimelineEntry(entry: entry)));

      expect(find.text('Logged by AI'), findsOneWidget);
    });

    testWidgets('shows image icon when imageRefs is non-empty',
        (tester) async {
      final entry = _makeEntry(imageRefs: ['img1.jpg']);
      await tester.pumpWidget(_wrap(TimelineEntry(entry: entry)));

      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    });

    testWidgets('hides image icon when imageRefs is empty', (tester) async {
      final entry = _makeEntry(imageRefs: []);
      await tester.pumpWidget(_wrap(TimelineEntry(entry: entry)));

      expect(find.byIcon(Icons.image_outlined), findsNothing);
    });

    testWidgets('hides connector line when isLast is true', (tester) async {
      final entry = _makeEntry();
      await tester.pumpWidget(_wrap(TimelineEntry(entry: entry, isLast: true)));

      // The connector is an Expanded > Container(width:2). When isLast,
      // there should be no Expanded widget inside the timeline column.
      final sizedBox = tester.widget<SizedBox>(
        find.byWidgetPredicate(
          (w) => w is SizedBox && w.width == 24,
        ),
      );
      final column = (sizedBox.child! as Column);
      final hasExpanded = column.children.any((c) => c is Expanded);
      expect(hasExpanded, isFalse);
    });

    testWidgets('shows connector line when isLast is false', (tester) async {
      final entry = _makeEntry();
      await tester
          .pumpWidget(_wrap(TimelineEntry(entry: entry, isLast: false)));

      final sizedBox = tester.widget<SizedBox>(
        find.byWidgetPredicate(
          (w) => w is SizedBox && w.width == 24,
        ),
      );
      final column = (sizedBox.child! as Column);
      final hasExpanded = column.children.any((c) => c is Expanded);
      expect(hasExpanded, isTrue);
    });

    testWidgets('dot colour is green for watered action', (tester) async {
      final entry = _makeEntry(actionType: ActionType.watered);
      await tester.pumpWidget(_wrap(TimelineEntry(entry: entry)));

      final dot = tester.widget<Container>(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).shape == BoxShape.circle,
        ),
      );
      final decoration = dot.decoration! as BoxDecoration;
      expect(decoration.color, AppColors.statusGreen);
    });

    testWidgets('dot colour is red for issueFound action', (tester) async {
      final entry = _makeEntry(actionType: ActionType.issueFound);
      await tester.pumpWidget(_wrap(TimelineEntry(entry: entry)));

      final dot = tester.widget<Container>(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).shape == BoxShape.circle,
        ),
      );
      final decoration = dot.decoration! as BoxDecoration;
      expect(decoration.color, AppColors.statusRed);
    });

    testWidgets('tag chip uses correct colours for fertilised',
        (tester) async {
      final entry = _makeEntry(actionType: ActionType.fertilised);
      await tester.pumpWidget(_wrap(TimelineEntry(entry: entry)));

      // Find the tag chip container by its text child
      final chipFinder = find.ancestor(
        of: find.text('Fertilised'),
        matching: find.byType(Container),
      );
      // The first Container ancestor with a BoxDecoration is the chip
      final containers = tester.widgetList<Container>(chipFinder);
      final chip = containers.firstWhere(
        (c) =>
            c.decoration is BoxDecoration &&
            (c.decoration as BoxDecoration).color != null,
      );
      final decoration = chip.decoration! as BoxDecoration;
      expect(decoration.color, AppColors.chipBlueBg);
    });
  });

  group('TimelineEntry static helpers', () {
    test('dotColor maps all action types', () {
      expect(TimelineEntry.dotColor(ActionType.watered), AppColors.statusGreen);
      expect(TimelineEntry.dotColor(ActionType.pruned), AppColors.statusAmber);
      expect(
          TimelineEntry.dotColor(ActionType.fertilised), AppColors.blueInfo);
      expect(
          TimelineEntry.dotColor(ActionType.issueFound), AppColors.statusRed);
      expect(
          TimelineEntry.dotColor(ActionType.repotted), AppColors.statusGreen);
      expect(TimelineEntry.dotColor(ActionType.other), Colors.grey);
    });

    test('actionLabel maps all action types', () {
      expect(TimelineEntry.actionLabel(ActionType.watered), 'Watered');
      expect(TimelineEntry.actionLabel(ActionType.pruned), 'Pruned');
      expect(TimelineEntry.actionLabel(ActionType.fertilised), 'Fertilised');
      expect(TimelineEntry.actionLabel(ActionType.issueFound), 'Issue found');
      expect(TimelineEntry.actionLabel(ActionType.repotted), 'Repotted');
      expect(TimelineEntry.actionLabel(ActionType.other), 'Other');
    });
  });
}
