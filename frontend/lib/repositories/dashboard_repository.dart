import '../models/dashboard_summary.dart';

abstract class DashboardRepository {
  Future<DashboardSummary> getDashboardSummary();
}
