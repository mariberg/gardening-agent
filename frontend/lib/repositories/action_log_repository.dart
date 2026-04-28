import '../models/action_log_entry.dart';

abstract class ActionLogRepository {
  Future<List<ActionLogEntry>> getLogsForPlant(String instanceId, {int limit, int offset});
  Future<ActionLogEntry> createLog(ActionLogEntry entry);
  Future<List<ActionLogEntry>> getRecentLogs(String instanceId, {int limit = 5});
  Future<List<ActionLogEntry>> getUnresolvedIssues();
}
