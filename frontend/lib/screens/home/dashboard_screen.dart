import 'package:flutter/material.dart';

import '../../data/repository_provider.dart';
import '../../models/action_log_entry.dart';
import '../../models/dashboard_summary.dart';
import '../../models/plant_instance.dart';
import '../../repositories/action_log_repository.dart';
import '../../repositories/dashboard_repository.dart';
import '../../repositories/plant_repository.dart';
import 'widgets/alert_card.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/plant_grid.dart';
import 'widgets/plants_section_header.dart';

/// The Home tab content — a scrollable dashboard displaying the garden overview.
///
/// Fetches data from [PlantRepository], [ActionLogRepository], and
/// [DashboardRepository] via [RepositoryProvider]. Shows a loading indicator
/// while data loads, an error message if the plant repository throws, and
/// silently hides the alert card if the action log repository throws.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String? _error;

  List<PlantInstance> _plants = [];
  List<ActionLogEntry> _unresolvedIssues = [];
  DashboardSummary _summary = const DashboardSummary(
    aiSummaryText: '',
    weatherChips: [],
    userName: 'Gardener',
  );

  @override
  void initState() {
    super.initState();
    // Schedule data fetch after the first frame so context is available.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final plantRepo = RepositoryProvider.of<PlantRepository>(context);
    final actionLogRepo = RepositoryProvider.of<ActionLogRepository>(context);
    final dashboardRepo = RepositoryProvider.of<DashboardRepository>(context);

    try {
      final plants = await plantRepo.getAllPlants();

      // Action log is non-critical — silently hide alert on failure.
      List<ActionLogEntry> issues = [];
      try {
        issues = await actionLogRepo.getUnresolvedIssues();
      } catch (e) {
        debugPrint('ActionLogRepository error (non-critical): $e');
      }

      // Dashboard summary is non-critical — use fallback on failure.
      DashboardSummary summary = const DashboardSummary(
        aiSummaryText: '',
        weatherChips: [],
        userName: 'Gardener',
      );
      try {
        summary = await dashboardRepo.getDashboardSummary();
      } catch (e) {
        debugPrint('DashboardRepository error (non-critical): $e');
      }

      if (!mounted) return;
      setState(() {
        _plants = plants;
        _unresolvedIssues = issues;
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      // PlantRepository failure is critical — show error.
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load plants. Please try again later.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.red),
        ),
      );
    }

    // Determine the most recent unresolved issue (sorted descending by date).
    ActionLogEntry? mostRecentIssue;
    String? issueNickname;
    if (_unresolvedIssues.isNotEmpty) {
      final sorted = List<ActionLogEntry>.from(_unresolvedIssues)
        ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      mostRecentIssue = sorted.first;

      // Look up the plant nickname for the issue.
      final matchingPlant = _plants.where(
        (p) => p.instanceId == mostRecentIssue!.instanceId,
      );
      issueNickname =
          matchingPlant.isNotEmpty ? matchingPlant.first.nickname : 'Unknown';
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardHeader(summary: _summary),
          if (mostRecentIssue != null)
            AlertCard(entry: mostRecentIssue, plantNickname: issueNickname!),
          const SizedBox(height: 16),
          PlantsSectionHeader(count: _plants.length),
          const SizedBox(height: 12),
          PlantGrid(plants: _plants),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
