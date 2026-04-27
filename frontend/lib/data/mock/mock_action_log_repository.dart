import '../../models/action_log_entry.dart';
import '../../repositories/action_log_repository.dart';

class MockActionLogRepository implements ActionLogRepository {
  final List<ActionLogEntry> _logs = [
    // ── plant-001: Cherry Tomato (9 entries) ──
    ActionLogEntry(
      actionId: 'log-001-01',
      instanceId: 'plant-001',
      actionType: ActionType.watered,
      title: 'Morning watering',
      notes: 'Gave a deep soak around the base, soil was quite dry.',
      loggedBy: LoggedBy.user,
      occurredAt: DateTime(2025, 6, 10, 8, 15),
    ),
    ActionLogEntry(
      actionId: 'log-001-02',
      instanceId: 'plant-001',
      actionType: ActionType.fertilised,
      title: 'Tomato feed applied',
      notes: 'Used liquid tomato fertiliser diluted to half strength.',
      loggedBy: LoggedBy.user,
      imageRefs: ['assets/photos/tomato_feed.jpg'],
      occurredAt: DateTime(2025, 6, 7, 10, 30),
    ),
    ActionLogEntry(
      actionId: 'log-001-03',
      instanceId: 'plant-001',
      actionType: ActionType.pruned,
      title: 'Side-shoot removal',
      notes: 'Pinched out three side shoots to direct energy to fruit trusses.',
      loggedBy: LoggedBy.user,
      occurredAt: DateTime(2025, 6, 4, 17, 0),
    ),
    ActionLogEntry(
      actionId: 'log-001-04',
      instanceId: 'plant-001',
      actionType: ActionType.issueFound,
      title: 'Blossom end rot spotted',
      notes: 'Two fruits on the lower truss showing dark patches at the base.',
      severity: Severity.moderate,
      loggedBy: LoggedBy.agent,
      imageRefs: ['assets/photos/tomato_ber_1.jpg', 'assets/photos/tomato_ber_2.jpg'],
      occurredAt: DateTime(2025, 5, 30, 14, 20),
    ),
    ActionLogEntry(
      actionId: 'log-001-05',
      instanceId: 'plant-001',
      actionType: ActionType.watered,
      title: 'Evening watering',
      notes: 'Light watering after a hot day.',
      loggedBy: LoggedBy.user,
      occurredAt: DateTime(2025, 5, 28, 19, 0),
    ),
    ActionLogEntry(
      actionId: 'log-001-06',
      instanceId: 'plant-001',
      actionType: ActionType.repotted,
      title: 'Moved to raised bed',
      notes: 'Transplanted from starter pot into raised bed A with fresh compost.',
      loggedBy: LoggedBy.user,
      imageRefs: ['assets/photos/tomato_repot.jpg'],
      occurredAt: DateTime(2025, 5, 20, 11, 0),
    ),
    ActionLogEntry(
      actionId: 'log-001-07',
      instanceId: 'plant-001',
      actionType: ActionType.other,
      title: 'Staked the main stem',
      notes: 'Added a bamboo cane and tied loosely with garden twine.',
      loggedBy: LoggedBy.user,
      occurredAt: DateTime(2025, 5, 15, 9, 45),
    ),
    ActionLogEntry(
      actionId: 'log-001-08',
      instanceId: 'plant-001',
      actionType: ActionType.watered,
      title: 'Routine watering',
      notes: null,
      loggedBy: LoggedBy.agent,
      occurredAt: DateTime(2025, 5, 10, 8, 0),
    ),
    ActionLogEntry(
      actionId: 'log-001-09',
      instanceId: 'plant-001',
      actionType: ActionType.fertilised,
      title: 'Initial feed',
      notes: 'Applied slow-release granules at planting time.',
      loggedBy: LoggedBy.user,
      occurredAt: DateTime(2025, 3, 15, 12, 0),
    ),

    // ── plant-002: Basil (9 entries) ──
    ActionLogEntry(
      actionId: 'log-002-01',
      instanceId: 'plant-002',
      actionType: ActionType.watered,
      title: 'Morning misting',
      notes: 'Light mist on leaves and soil surface.',
      loggedBy: LoggedBy.user,
      occurredAt: DateTime(2025, 6, 11, 7, 30),
    ),
    ActionLogEntry(
      actionId: 'log-002-02',
      instanceId: 'plant-002',
      actionType: ActionType.issueFound,
      title: 'Yellowing lower leaves',
      notes: 'Bottom leaves turning yellow, possible overwatering.',
      severity: Severity.mild,
      loggedBy: LoggedBy.agent,
      imageRefs: ['assets/photos/basil_yellow.jpg'],
      occurredAt: DateTime(2025, 6, 9, 16, 0),
    ),
    ActionLogEntry(
      actionId: 'log-002-03',
      instanceId: 'plant-002',
      actionType: ActionType.pruned,
      title: 'Harvested top leaves',
      notes: 'Pinched off the top sets of leaves to encourage bushier growth.',
      loggedBy: LoggedBy.user,
      occurredAt: DateTime(2025, 6, 5, 18, 30),
    ),
    ActionLogEntry(
      actionId: 'log-002-04',
      instanceId: 'plant-002',
      actionType: ActionType.fertilised,
      title: 'Liquid herb feed',
      notes: 'Diluted organic herb fertiliser, applied to soil.',
      loggedBy: LoggedBy.user,
      occurredAt: DateTime(2025, 5, 29, 9, 0),
    ),
    ActionLogEntry(
      actionId: 'log-002-05',
      instanceId: 'plant-002',
      actionType: ActionType.watered,
      title: 'Deep watering',
      notes: 'Soil was very dry, gave a thorough soak.',
      loggedBy: LoggedBy.user,
      occurredAt: DateTime(2025, 5, 25, 8, 0),
    ),
    ActionLogEntry(
      actionId: 'log-002-06',
      instanceId: 'plant-002',
      actionType: ActionType.repotted,
      title: 'Moved to herb planter',
      notes: 'Transferred from seed tray into the herb planter with drainage holes.',
      loggedBy: LoggedBy.user,
      imageRefs: ['assets/photos/basil_repot.jpg'],
      occurredAt: DateTime(2025, 5, 10, 14, 0),
    ),
    ActionLogEntry(
      actionId: 'log-002-07',
      instanceId: 'plant-002',
      actionType: ActionType.other,
      title: 'Companion planted with tomatoes',
      notes: 'Placed basil near the tomato bed to help deter pests.',
      loggedBy: LoggedBy.user,
      occurredAt: DateTime(2025, 5, 5, 10, 0),
    ),
    ActionLogEntry(
      actionId: 'log-002-08',
      instanceId: 'plant-002',
      actionType: ActionType.watered,
      title: 'Post-transplant watering',
      notes: 'Settled the soil after repotting.',
      loggedBy: LoggedBy.agent,
      occurredAt: DateTime(2025, 4, 2, 15, 0),
    ),
    ActionLogEntry(
      actionId: 'log-002-09',
      instanceId: 'plant-002',
      actionType: ActionType.issueFound,
      title: 'Aphids on new growth',
      notes: 'Small cluster of aphids found on the newest leaf tips.',
      severity: Severity.mild,
      loggedBy: LoggedBy.user,
      imageRefs: ['assets/photos/basil_aphids.jpg'],
      occurredAt: DateTime(2025, 5, 18, 11, 30),
    ),

    // ── plant-003: Courgette (9 entries) ──
    ActionLogEntry(
      actionId: 'log-003-01',
      instanceId: 'plant-003',
      actionType: ActionType.issueFound,
      title: 'Powdery mildew detected',
      notes: 'White powdery coating on upper leaf surfaces, spreading quickly.',
      severity: Severity.severe,
      loggedBy: LoggedBy.agent,
      imageRefs: ['assets/photos/courgette_mildew_1.jpg', 'assets/photos/courgette_mildew_2.jpg'],
      occurredAt: DateTime(2025, 6, 12, 9, 0),
    ),
    ActionLogEntry(
      actionId: 'log-003-02',
      instanceId: 'plant-003',
      actionType: ActionType.watered,
      title: 'Base watering only',
      notes: 'Watered at the base to avoid wetting leaves — mildew precaution.',
      loggedBy: LoggedBy.user,
      occurredAt: DateTime(2025, 6, 10, 7, 45),
    ),
    ActionLogEntry(
      actionId: 'log-003-03',
      instanceId: 'plant-003',
      actionType: ActionType.pruned,
      title: 'Removed affected leaves',
      notes: 'Cut away six leaves showing heavy mildew. Disposed in waste bin, not compost.',
      loggedBy: LoggedBy.user,
      imageRefs: ['assets/photos/courgette_pruned.jpg'],
      occurredAt: DateTime(2025, 6, 8, 16, 30),
    ),
    ActionLogEntry(
      actionId: 'log-003-04',
      instanceId: 'plant-003',
      actionType: ActionType.fertilised,
      title: 'Potash feed',
      notes: 'Applied high-potash feed to support fruiting.',
      loggedBy: LoggedBy.user,
      occurredAt: DateTime(2025, 6, 1, 10, 0),
    ),
    ActionLogEntry(
      actionId: 'log-003-05',
      instanceId: 'plant-003',
      actionType: ActionType.other,
      title: 'Milk spray treatment',
      notes: 'Sprayed diluted milk solution (1:9) on leaves as organic mildew treatment.',
      loggedBy: LoggedBy.user,
      occurredAt: DateTime(2025, 5, 28, 8, 30),
    ),
    ActionLogEntry(
      actionId: 'log-003-06',
      instanceId: 'plant-003',
      actionType: ActionType.watered,
      title: 'Morning watering',
      notes: 'Deep soak, soil was cracking from the heat.',
      loggedBy: LoggedBy.user,
      occurredAt: DateTime(2025, 5, 22, 7, 0),
    ),
    ActionLogEntry(
      actionId: 'log-003-07',
      instanceId: 'plant-003',
      actionType: ActionType.repotted,
      title: 'Planted out in raised bed',
      notes: 'Moved from greenhouse pot to raised bed B. Added mycorrhizal fungi to planting hole.',
      loggedBy: LoggedBy.user,
      imageRefs: ['assets/photos/courgette_planted.jpg'],
      occurredAt: DateTime(2025, 4, 20, 11, 0),
    ),
    ActionLogEntry(
      actionId: 'log-003-08',
      instanceId: 'plant-003',
      actionType: ActionType.issueFound,
      title: 'Slug damage on seedling',
      notes: 'Holes in lower leaves overnight. Set up copper tape barrier.',
      severity: Severity.moderate,
      loggedBy: LoggedBy.user,
      imageRefs: ['assets/photos/courgette_slug.jpg'],
      occurredAt: DateTime(2025, 3, 25, 8, 0),
    ),
    ActionLogEntry(
      actionId: 'log-003-09',
      instanceId: 'plant-003',
      actionType: ActionType.watered,
      title: 'Seedling watering',
      notes: 'Gentle watering with a fine rose.',
      loggedBy: LoggedBy.agent,
      occurredAt: DateTime(2025, 3, 5, 9, 0),
    ),
  ];

  @override
  Future<List<ActionLogEntry>> getLogsForPlant(
    String instanceId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final filtered = _logs
        .where((log) => log.instanceId == instanceId)
        .toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    final end = (offset + limit).clamp(0, filtered.length);
    return filtered.sublist(offset.clamp(0, filtered.length), end);
  }

  @override
  Future<ActionLogEntry> createLog(ActionLogEntry entry) async {
    _logs.insert(0, entry);
    return entry;
  }

  @override
  Future<List<ActionLogEntry>> getRecentLogs(
    String instanceId, {
    int limit = 5,
  }) async {
    return getLogsForPlant(instanceId, limit: limit, offset: 0);
  }
}
