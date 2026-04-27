import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden_app/theme/app_colors.dart';
import 'package:garden_app/widgets/ai_insight_card.dart';

void main() {
  Widget buildCard(String insightText) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: AIInsightCard(insightText: insightText),
        ),
      ),
    );
  }

  group('AIInsightCard', () {
    testWidgets('renders AI badge icon and label', (tester) async {
      await tester.pumpWidget(buildCard('Some insight'));

      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.text('AI personalised insight'), findsOneWidget);
    });

    testWidgets('renders insight text body', (tester) async {
      const text = 'Your tomato is thriving! Consider adding support stakes.';
      await tester.pumpWidget(buildCard(text));

      expect(find.text(text), findsOneWidget);
    });

    testWidgets('uses correct card styling (background, border, radius)',
        (tester) async {
      await tester.pumpWidget(buildCard('Test insight'));

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration! as BoxDecoration;

      expect(decoration.color, AppColors.lightGreen);
      expect(decoration.border, Border.all(color: AppColors.greenBorder));
      expect(decoration.borderRadius, BorderRadius.circular(12));
    });

    testWidgets('AI icon uses activeGreen colour', (tester) async {
      await tester.pumpWidget(buildCard('Test'));

      final icon = tester.widget<Icon>(find.byIcon(Icons.auto_awesome));
      expect(icon.color, AppColors.activeGreen);
    });
  });
}
