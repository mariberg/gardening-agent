import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden_app/theme/app_colors.dart';
import 'package:garden_app/widgets/status_chip.dart';

void main() {
  Widget buildChip(StatusChipVariant variant, String label) {
    return MaterialApp(
      home: Scaffold(body: StatusChip(label: label, variant: variant)),
    );
  }

  group('StatusChip', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(buildChip(StatusChipVariant.green, 'Thriving'));
      expect(find.text('Thriving'), findsOneWidget);
    });

    testWidgets('green variant uses correct colours', (tester) async {
      await tester.pumpWidget(buildChip(StatusChipVariant.green, 'Thriving'));

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration! as BoxDecoration;

      expect(decoration.color, AppColors.chipGreenBg);
      expect(decoration.border, Border.all(color: AppColors.chipGreenBorder));
      expect(decoration.borderRadius, BorderRadius.circular(4));
    });

    testWidgets('amber variant uses correct colours', (tester) async {
      await tester.pumpWidget(buildChip(StatusChipVariant.amber, 'Water tomorrow'));

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration! as BoxDecoration;

      expect(decoration.color, AppColors.chipAmberBg);
      expect(decoration.border, Border.all(color: AppColors.chipAmberBorder));
    });

    testWidgets('blue variant uses correct colours', (tester) async {
      await tester.pumpWidget(buildChip(StatusChipVariant.blue, 'Full sun'));

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration! as BoxDecoration;

      expect(decoration.color, AppColors.chipBlueBg);
      expect(decoration.border, Border.all(color: AppColors.chipBlueBorder));
    });

    testWidgets('text style has ~9sp font size and semibold weight', (tester) async {
      await tester.pumpWidget(buildChip(StatusChipVariant.green, 'Thriving'));

      final text = tester.widget<Text>(find.text('Thriving'));
      expect(text.style?.fontSize, 9);
      expect(text.style?.fontWeight, FontWeight.w600);
      expect(text.style?.color, AppColors.chipGreenText);
    });

    testWidgets('red variant uses correct colours', (tester) async {
      await tester.pumpWidget(buildChip(StatusChipVariant.red, 'Alert'));

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration! as BoxDecoration;

      expect(decoration.color, AppColors.redBg);
      expect(decoration.border, Border.all(color: AppColors.redBorder));
    });
  });
}
