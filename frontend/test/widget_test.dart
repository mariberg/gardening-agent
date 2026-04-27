import 'package:flutter_test/flutter_test.dart';
import 'package:garden_app/main.dart';

void main() {
  testWidgets('App renders garden list screen', (WidgetTester tester) async {
    await tester.pumpWidget(const GardenApp());
    await tester.pumpAndSettle();

    expect(find.text('My Garden'), findsOneWidget);
    // Verify plant cards from mock data are displayed
    expect(find.text('Cherry Tomato'), findsOneWidget);
    expect(find.text('Basil'), findsOneWidget);
    expect(find.text('Courgette'), findsOneWidget);
  });
}
