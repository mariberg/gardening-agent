import 'package:flutter_test/flutter_test.dart';
import 'package:garden_app/main.dart';
import 'package:garden_app/screens/home/app_shell.dart';

void main() {
  testWidgets('App launches into AppShell with Home tab selected',
      (WidgetTester tester) async {
    await tester.pumpWidget(const GardenApp());
    await tester.pumpAndSettle();

    // Verify AppShell is rendered
    expect(find.byType(AppShell), findsOneWidget);

    // Verify bottom navigation bar with all four tabs
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Water'), findsOneWidget);
    expect(find.text('Plants'), findsAtLeast(1));
    expect(find.text('Profile'), findsOneWidget);

    // Verify dashboard content is displayed (plant cards from mock data)
    expect(find.text('YOUR GARDEN'), findsOneWidget);
  });
}
