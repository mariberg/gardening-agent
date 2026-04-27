import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden_app/models/care_instruction.dart';
import 'package:garden_app/theme/app_colors.dart';
import 'package:garden_app/widgets/care_instruction_card.dart';

void main() {
  const baseInstruction = CareInstruction(
    instructionId: 'ci-1',
    speciesId: 'sp-1',
    title: 'Water regularly',
    body: 'Keep soil moist but not waterlogged during growing season.',
    sourceType: SourceType.rhs,
  );

  Widget buildCard(CareInstruction instruction) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CareInstructionCard(instruction: instruction),
        ),
      ),
    );
  }

  group('CareInstructionCard', () {
    testWidgets('renders title and body text', (tester) async {
      await tester.pumpWidget(buildCard(baseInstruction));

      expect(find.text('Water regularly'), findsOneWidget);
      expect(
        find.text('Keep soil moist but not waterlogged during growing season.'),
        findsOneWidget,
      );
    });

    testWidgets('renders source label for each SourceType', (tester) async {
      for (final type in SourceType.values) {
        final instruction = CareInstruction(
          instructionId: 'ci-${type.name}',
          speciesId: 'sp-1',
          title: 'Title',
          body: 'Body',
          sourceType: type,
        );
        await tester.pumpWidget(buildCard(instruction));

        final expected = CareInstructionCard.sourceLabel(type);
        expect(find.text(expected), findsOneWidget);
      }
    });

    testWidgets('does not show AI verified badge when aiVerified is false',
        (tester) async {
      await tester.pumpWidget(buildCard(baseInstruction));

      expect(find.byIcon(Icons.verified), findsNothing);
      expect(find.textContaining('AI verified'), findsNothing);
    });

    testWidgets('shows AI verified badge with confidence when aiVerified is true',
        (tester) async {
      const verified = CareInstruction(
        instructionId: 'ci-2',
        speciesId: 'sp-1',
        title: 'Prune in spring',
        body: 'Cut back dead growth in early spring.',
        sourceType: SourceType.book,
        aiVerified: true,
        aiConfidence: 0.92,
      );
      await tester.pumpWidget(buildCard(verified));

      expect(find.byIcon(Icons.verified), findsOneWidget);
      expect(find.text('AI verified · 92%'), findsOneWidget);
    });

    testWidgets('shows AI verified badge without confidence when confidence is null',
        (tester) async {
      const verified = CareInstruction(
        instructionId: 'ci-3',
        speciesId: 'sp-1',
        title: 'Feed monthly',
        body: 'Use balanced fertiliser once a month.',
        sourceType: SourceType.forum,
        aiVerified: true,
      );
      await tester.pumpWidget(buildCard(verified));

      expect(find.byIcon(Icons.verified), findsOneWidget);
      expect(find.text('AI verified'), findsOneWidget);
    });

    testWidgets('uses correct card styling (background, border, radius)',
        (tester) async {
      await tester.pumpWidget(buildCard(baseInstruction));

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration! as BoxDecoration;

      expect(decoration.color, AppColors.lightGreen);
      expect(decoration.border, Border.all(color: AppColors.greenBorder));
      expect(decoration.borderRadius, BorderRadius.circular(12));
    });

    testWidgets('sourceLabel returns correct strings', (tester) async {
      expect(CareInstructionCard.sourceLabel(SourceType.rhs), 'RHS');
      expect(CareInstructionCard.sourceLabel(SourceType.forum), 'Forum');
      expect(CareInstructionCard.sourceLabel(SourceType.book), 'Book');
      expect(CareInstructionCard.sourceLabel(SourceType.other), 'Other');
    });
  });
}
