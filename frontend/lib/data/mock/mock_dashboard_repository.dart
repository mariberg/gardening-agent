import '../../models/dashboard_summary.dart';
import '../../repositories/dashboard_repository.dart';

class MockDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardSummary> getDashboardSummary() async {
    return const DashboardSummary(
      aiSummaryText:
          'Rain expected tomorrow — hold off watering your tomatoes. '
          'Your basil is due for pruning; pinching the flower buds now will '
          'extend the harvest by weeks.',
      weatherChips: [
        WeatherChip(label: '18°C today'),
        WeatherChip(label: 'Rain tomorrow'),
      ],
      userName: 'Alex',
    );
  }
}
