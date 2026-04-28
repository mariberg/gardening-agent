import 'package:flutter_test/flutter_test.dart';
import 'package:garden_app/data/mock/mock_dashboard_repository.dart';
import 'package:garden_app/data/mock/mock_action_log_repository.dart';
import 'package:garden_app/models/action_log_entry.dart';

void main() {
  test('MockDashboardRepository can be instantiated and returns data', () async {
    final repo = MockDashboardRepository();
    final summary = await repo.getDashboardSummary();

    expect(summary.userName, 'Alex');
    expect(summary.aiSummaryText, isNotEmpty);
    expect(summary.weatherChips.length, greaterThanOrEqualTo(2));
    expect(summary.weatherChips[0].label, '18°C today');
    expect(summary.weatherChips[1].label, 'Rain tomorrow');
  });

  test('MockActionLogRepository can be instantiated and getUnresolvedIssues works', () async {
    final repo = MockActionLogRepository();
    final issues = await repo.getUnresolvedIssues();

    expect(issues, isNotEmpty);
    for (final issue in issues) {
      expect(issue.actionType, ActionType.issueFound);
    }
    // Verify sorted by occurredAt descending
    for (int i = 0; i < issues.length - 1; i++) {
      expect(
        issues[i].occurredAt.isAfter(issues[i + 1].occurredAt) ||
            issues[i].occurredAt.isAtSameMomentAs(issues[i + 1].occurredAt),
        isTrue,
      );
    }
  });
}
