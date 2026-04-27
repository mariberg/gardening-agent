class ProgressionComparison {
  final String previousPhotoId;
  final String previousAssetPath;
  final DateTime previousDate;
  final String currentAssetPath;
  final DateTime currentDate;
  final String description;

  const ProgressionComparison({
    required this.previousPhotoId,
    required this.previousAssetPath,
    required this.previousDate,
    required this.currentAssetPath,
    required this.currentDate,
    required this.description,
  });
}

class AIAnalysis {
  final String photoId;
  final String conditionName;
  final double confidence;
  final String analysisText;
  final ProgressionComparison? progression;

  const AIAnalysis({
    required this.photoId,
    required this.conditionName,
    required this.confidence,
    required this.analysisText,
    this.progression,
  });
}
