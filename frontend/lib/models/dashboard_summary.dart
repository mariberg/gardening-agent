class WeatherChip {
  final String label;
  final String? icon;

  const WeatherChip({required this.label, this.icon});
}

class DashboardSummary {
  final String aiSummaryText;
  final List<WeatherChip> weatherChips;
  final String userName;

  const DashboardSummary({
    required this.aiSummaryText,
    required this.weatherChips,
    required this.userName,
  });
}
