enum ActionType { watered, pruned, fertilised, issueFound, repotted, other }

enum Severity { mild, moderate, severe }

enum LoggedBy { user, agent }

class ActionLogEntry {
  final String actionId;
  final String instanceId;
  final ActionType actionType;
  final String? title;
  final String? notes;
  final Severity? severity;
  final LoggedBy loggedBy;
  final List<String> imageRefs;
  final DateTime occurredAt;
  final bool isDraft;

  const ActionLogEntry({
    required this.actionId,
    required this.instanceId,
    required this.actionType,
    this.title,
    this.notes,
    this.severity,
    required this.loggedBy,
    this.imageRefs = const [],
    required this.occurredAt,
    this.isDraft = false,
  });
}
