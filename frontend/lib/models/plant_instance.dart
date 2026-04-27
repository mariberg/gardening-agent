enum PlantStatus { thriving, needsAttention, alert }

class PlantInstance {
  final String instanceId;
  final String speciesId;
  final String nickname;
  final String emoji;
  final String gardenLocation;
  final DateTime plantedAt;
  final PlantStatus status;
  final String statusLabel;
  final DateTime? nextWateringDate;
  final String sunRequirement;
  final String speciesCommonName;
  final String speciesLatinName;
  final String? aiInsightText;

  const PlantInstance({
    required this.instanceId,
    required this.speciesId,
    required this.nickname,
    required this.emoji,
    required this.gardenLocation,
    required this.plantedAt,
    required this.status,
    required this.statusLabel,
    this.nextWateringDate,
    required this.sunRequirement,
    required this.speciesCommonName,
    required this.speciesLatinName,
    this.aiInsightText,
  });
}
