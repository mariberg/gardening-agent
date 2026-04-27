import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden_app/theme/app_colors.dart';
import 'package:garden_app/widgets/app_filter_chip.dart';

void main() {
  Widget buildChip({
    required bool isSelected,
    String label = 'All',
    VoidCallback? onTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: AppFilterChip(
          label: label,
          isSelected: isSelected,
          onTap: onTap ?? () {},
        ),
      ),
    );
  }

  group('AppFilterChip', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(buildChip(isSelected: false, label: 'Issues'));
      expect(find.text('Issues'), findsOneWidget);
    });

    testWidgets('active state uses dark green fill and light text',
        (tester) async {
      await tester.pumpWidget(buildChip(isSelected: true));

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration! as BoxDecoration;

      expect(decoration.color, AppColors.filterChipActiveBg);
      expect(decoration.borderRadius, BorderRadius.circular(20));

      final text = tester.widget<Text>(find.text('All'));
      expect(text.style?.color, AppColors.filterChipActiveText);
    });

    testWidgets('inactive state uses transparent background and border',
        (tester) async {
      await tester.pumpWidget(buildChip(isSelected: false));

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration! as BoxDecoration;

      expect(decoration.color, Colors.transparent);
      expect(
        decoration.border,
        Border.all(color: Colors.grey.shade400),
      );

      final text = tester.widget<Text>(find.text('All'));
      expect(text.style?.color, Colors.black54);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildChip(isSelected: false, onTap: () => tapped = true),
      );

      await tester.tap(find.text('All'));
      expect(tapped, isTrue);
    });
  });
}
