import 'package:flutter/material.dart';
import '../../../data/repository_provider.dart';
import '../../../models/action_log_entry.dart';
import '../../../models/plant_instance.dart';
import '../../../repositories/action_log_repository.dart';
import '../../../widgets/timeline_entry.dart';

/// Full paginated timeline of all action log entries for a plant instance.
///
/// Loads entries 20 at a time in reverse chronological order and fetches more
/// when the user scrolls near the bottom.
///
/// Requirements: 4.1, 4.2, 4.3, 4.4
class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key, required this.plant});

  final PlantInstance plant;

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  static const _pageSize = 20;

  final ScrollController _scrollController = ScrollController();
  final List<ActionLogEntry> _entries = [];

  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entries.isEmpty && !_isLoading) {
      _loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    final repo = RepositoryProvider.of<ActionLogRepository>(context);
    final newEntries = await repo.getLogsForPlant(
      widget.plant.instanceId,
      limit: _pageSize,
      offset: _entries.length,
    );

    setState(() {
      _entries.addAll(newEntries);
      _hasMore = newEntries.length == _pageSize;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_entries.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_entries.isEmpty && !_isLoading) {
      return const Center(
        child: Text('No history entries yet.'),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _entries.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _entries.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return TimelineEntry(
          entry: _entries[index],
          isLast: index == _entries.length - 1 && !_hasMore,
        );
      },
    );
  }
}
