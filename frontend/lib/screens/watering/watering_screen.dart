import 'package:flutter/material.dart';
import '../../data/repository_provider.dart';
import '../../models/action_log_entry.dart';
import '../../models/plant_instance.dart';
import '../../repositories/action_log_repository.dart';
import '../../repositories/plant_repository.dart';
import 'widgets/bulk_action_bar.dart';
import 'widgets/confirmation_sheet.dart';
import 'widgets/section_header.dart';
import 'widgets/watering_header.dart';
import 'widgets/watering_plant_item.dart';

/// The main Watering screen that displays plants due for watering today,
/// supports multi-selection, and allows batch-marking plants as watered.
class WateringScreen extends StatefulWidget {
  const WateringScreen({super.key});

  @override
  State<WateringScreen> createState() => _WateringScreenState();
}

class _WateringScreenState extends State<WateringScreen> {
  List<PlantInstance> _plants = [];
  Set<String> _todaysLogs = {}; // instanceIds watered today (from repo)
  Set<String> _selectedIds = {}; // currently selected
  final Set<String> _justWateredIds = {}; // watered this session
  bool _isLoading = true;

  bool _hasLoadedData = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedData) {
      _hasLoadedData = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final plantRepo = RepositoryProvider.of<PlantRepository>(context);
    final logRepo = RepositoryProvider.of<ActionLogRepository>(context);

    final allPlants = await plantRepo.getAllPlants();
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day + 1);

    final duePlants = allPlants.where((plant) {
      return plant.nextWateringDate != null &&
          plant.nextWateringDate!.isBefore(todayEnd);
    }).toList();

    final todaysLogs = await logRepo.getTodaysWateringLogs();
    final loggedInstanceIds =
        todaysLogs.map((log) => log.instanceId).toSet();

    setState(() {
      _plants = duePlants;
      _todaysLogs = loggedInstanceIds;
      _isLoading = false;
    });
  }

  /// Returns true if the plant has already been watered today,
  /// either from persisted logs or from this session.
  bool _isDone(String instanceId) =>
      _todaysLogs.contains(instanceId) || _justWateredIds.contains(instanceId);

  /// Returns true if all pending (non-done) plants are currently selected.
  bool get _allPendingSelected {
    final pending = _plants.where((p) => !_isDone(p.instanceId));
    return pending.isNotEmpty &&
        pending.every((p) => _selectedIds.contains(p.instanceId));
  }

  /// Returns the plants list sorted by ordering rules (Req 7.2):
  /// 1. Pending plants first (overdue sorted by days overdue descending, then due today)
  /// 2. Done plants at the end
  List<PlantInstance> get _sortedPlants {
    final pending = _plants.where((p) => !_isDone(p.instanceId)).toList();
    final done = _plants.where((p) => _isDone(p.instanceId)).toList();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    pending.sort((a, b) {
      final aDays = today
          .difference(DateTime(a.nextWateringDate!.year,
              a.nextWateringDate!.month, a.nextWateringDate!.day))
          .inDays;
      final bDays = today
          .difference(DateTime(b.nextWateringDate!.year,
              b.nextWateringDate!.month, b.nextWateringDate!.day))
          .inDays;
      return bDays.compareTo(aDays); // descending — most overdue first
    });

    return [...pending, ...done];
  }

  /// Toggles selection for a single plant.
  /// Done items cannot be selected (Req 2.4, 6.4).
  void _toggleSelect(String instanceId) {
    if (_isDone(instanceId)) return;
    setState(() {
      if (_selectedIds.contains(instanceId)) {
        _selectedIds.remove(instanceId);
      } else {
        _selectedIds.add(instanceId);
      }
    });
  }

  /// Toggles select-all: if all pending are selected, clears selection;
  /// otherwise selects all pending plants (Req 3.1, 3.2).
  void _toggleSelectAll() {
    setState(() {
      if (_allPendingSelected) {
        _selectedIds.clear();
      } else {
        _selectedIds = _plants
            .where((p) => !_isDone(p.instanceId))
            .map((p) => p.instanceId)
            .toSet();
      }
    });
  }

  /// Shows the confirmation bottom sheet with the currently selected plants.
  /// The sheet dismisses on swipe/tap-outside without action (Req 5.6).
  void _showConfirmationSheet() {
    final selectedPlants = _plants
        .where((p) => _selectedIds.contains(p.instanceId))
        .toList();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ConfirmationSheet(
        selectedPlants: selectedPlants,
        onConfirm: _confirmWatering,
      ),
    );
  }

  /// Creates an ActionLogEntry for each selected plant and transitions
  /// them to the done state (Req 5.4, 6.1, 6.3).
  Future<void> _confirmWatering() async {
    final repo = RepositoryProvider.of<ActionLogRepository>(context);
    for (final id in _selectedIds) {
      await repo.createLog(ActionLogEntry(
        actionId: 'log-${DateTime.now().millisecondsSinceEpoch}-$id',
        instanceId: id,
        actionType: ActionType.watered,
        loggedBy: LoggedBy.user,
        occurredAt: DateTime.now(),
      ));
    }
    setState(() {
      _justWateredIds.addAll(_selectedIds);
      _selectedIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_plants.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text(
            'All caught up! 🌱',
            style: TextStyle(fontSize: 18, color: Colors.black54),
          ),
        ),
      );
    }

    final sortedPlants = _sortedPlants;
    final doneCount =
        _plants.where((p) => _isDone(p.instanceId)).length;

    return Scaffold(
      body: Column(
        children: [
          WateringHeader(
            allSelected: _allPendingSelected,
            onSelectAll: _toggleSelectAll,
          ),
          if (_selectedIds.isNotEmpty)
            BulkActionBar(
              selectedCount: _selectedIds.length,
              onMarkWatered: _showConfirmationSheet,
            ),
          SectionHeader(
            doneCount: doneCount,
            totalCount: _plants.length,
          ),
          Expanded(
            child: ListView.builder(
              itemCount: sortedPlants.length,
              itemBuilder: (context, index) {
                final plant = sortedPlants[index];
                return WateringPlantItem(
                  plant: plant,
                  isSelected: _selectedIds.contains(plant.instanceId),
                  isDone: _isDone(plant.instanceId),
                  onTap: () => _toggleSelect(plant.instanceId),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
