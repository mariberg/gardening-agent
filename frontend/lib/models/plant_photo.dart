import 'action_log_entry.dart';

class PlantPhoto {
  final String photoId;
  final String instanceId;
  final String assetPath;
  final ActionType actionTag;
  final DateTime takenAt;
  final bool hasAIAnalysis;
  final String? caption;

  const PlantPhoto({
    required this.photoId,
    required this.instanceId,
    required this.assetPath,
    required this.actionTag,
    required this.takenAt,
    this.hasAIAnalysis = false,
    this.caption,
  });
}
