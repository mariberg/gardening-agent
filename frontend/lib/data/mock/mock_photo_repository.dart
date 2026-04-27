import '../../models/action_log_entry.dart';
import '../../models/ai_analysis.dart';
import '../../models/plant_photo.dart';
import '../../repositories/photo_repository.dart';

class MockPhotoRepository implements PhotoRepository {
  // Tag filter label → ActionType mapping
  static final Map<String, ActionType> _tagFilterMap = {
    'Issues': ActionType.issueFound,
    'Healthy': ActionType.watered,
    'After care': ActionType.pruned,
  };

  final List<PlantPhoto> _photos = [
    // ── plant-001: Cherry Tomato ──
    PlantPhoto(
      photoId: 'photo-001-01',
      instanceId: 'plant-001',
      assetPath: 'assets/placeholder/tomato_01.png',
      actionTag: ActionType.watered,
      takenAt: DateTime(2025, 6, 10),
      caption: 'After morning watering',
    ),
    PlantPhoto(
      photoId: 'photo-001-02',
      instanceId: 'plant-001',
      assetPath: 'assets/placeholder/tomato_02.png',
      actionTag: ActionType.fertilised,
      takenAt: DateTime(2025, 6, 5),
      caption: 'Post-fertiliser check',
    ),
    PlantPhoto(
      photoId: 'photo-001-03',
      instanceId: 'plant-001',
      assetPath: 'assets/placeholder/tomato_03.png',
      actionTag: ActionType.pruned,
      takenAt: DateTime(2025, 5, 28),
      caption: 'Pruned lower suckers',
    ),
    PlantPhoto(
      photoId: 'photo-001-04',
      instanceId: 'plant-001',
      assetPath: 'assets/placeholder/tomato_04.png',
      actionTag: ActionType.issueFound,
      takenAt: DateTime(2025, 5, 20),
      hasAIAnalysis: true,
      caption: 'Yellowing leaves spotted',
    ),
    PlantPhoto(
      photoId: 'photo-001-05',
      instanceId: 'plant-001',
      assetPath: 'assets/placeholder/tomato_05.png',
      actionTag: ActionType.watered,
      takenAt: DateTime(2025, 5, 15),
      caption: 'Healthy growth update',
    ),
    PlantPhoto(
      photoId: 'photo-001-06',
      instanceId: 'plant-001',
      assetPath: 'assets/placeholder/tomato_06.png',
      actionTag: ActionType.repotted,
      takenAt: DateTime(2025, 4, 10),
      caption: 'Moved to raised bed',
    ),
    PlantPhoto(
      photoId: 'photo-001-07',
      instanceId: 'plant-001',
      assetPath: 'assets/placeholder/tomato_07.png',
      actionTag: ActionType.issueFound,
      takenAt: DateTime(2025, 4, 5),
      hasAIAnalysis: true,
      caption: 'Early leaf curl',
    ),

    // ── plant-002: Basil ──
    PlantPhoto(
      photoId: 'photo-002-01',
      instanceId: 'plant-002',
      assetPath: 'assets/placeholder/basil_01.png',
      actionTag: ActionType.watered,
      takenAt: DateTime(2025, 6, 12),
      caption: 'Morning watering',
    ),
    PlantPhoto(
      photoId: 'photo-002-02',
      instanceId: 'plant-002',
      assetPath: 'assets/placeholder/basil_02.png',
      actionTag: ActionType.issueFound,
      takenAt: DateTime(2025, 6, 8),
      hasAIAnalysis: true,
      caption: 'Yellow lower leaves',
    ),
    PlantPhoto(
      photoId: 'photo-002-03',
      instanceId: 'plant-002',
      assetPath: 'assets/placeholder/basil_03.png',
      actionTag: ActionType.pruned,
      takenAt: DateTime(2025, 5, 30),
      caption: 'Pinched flower buds',
    ),
    PlantPhoto(
      photoId: 'photo-002-04',
      instanceId: 'plant-002',
      assetPath: 'assets/placeholder/basil_04.png',
      actionTag: ActionType.fertilised,
      takenAt: DateTime(2025, 5, 22),
      caption: 'Liquid feed applied',
    ),
    PlantPhoto(
      photoId: 'photo-002-05',
      instanceId: 'plant-002',
      assetPath: 'assets/placeholder/basil_05.png',
      actionTag: ActionType.watered,
      takenAt: DateTime(2025, 5, 10),
      caption: 'Healthy foliage',
    ),
    PlantPhoto(
      photoId: 'photo-002-06',
      instanceId: 'plant-002',
      assetPath: 'assets/placeholder/basil_06.png',
      actionTag: ActionType.other,
      takenAt: DateTime(2025, 4, 15),
      caption: 'Initial planting',
    ),

    // ── plant-003: Courgette ──
    PlantPhoto(
      photoId: 'photo-003-01',
      instanceId: 'plant-003',
      assetPath: 'assets/placeholder/courgette_01.png',
      actionTag: ActionType.issueFound,
      takenAt: DateTime(2025, 6, 11),
      hasAIAnalysis: true,
      caption: 'Powdery mildew spreading',
    ),
    PlantPhoto(
      photoId: 'photo-003-02',
      instanceId: 'plant-003',
      assetPath: 'assets/placeholder/courgette_02.png',
      actionTag: ActionType.watered,
      takenAt: DateTime(2025, 6, 7),
      caption: 'Deep watering session',
    ),
    PlantPhoto(
      photoId: 'photo-003-03',
      instanceId: 'plant-003',
      assetPath: 'assets/placeholder/courgette_03.png',
      actionTag: ActionType.pruned,
      takenAt: DateTime(2025, 5, 25),
      caption: 'Removed affected leaves',
    ),
    PlantPhoto(
      photoId: 'photo-003-04',
      instanceId: 'plant-003',
      assetPath: 'assets/placeholder/courgette_04.png',
      actionTag: ActionType.issueFound,
      takenAt: DateTime(2025, 5, 18),
      hasAIAnalysis: true,
      caption: 'First mildew signs',
    ),
    PlantPhoto(
      photoId: 'photo-003-05',
      instanceId: 'plant-003',
      assetPath: 'assets/placeholder/courgette_05.png',
      actionTag: ActionType.fertilised,
      takenAt: DateTime(2025, 5, 5),
      caption: 'Organic feed added',
    ),
    PlantPhoto(
      photoId: 'photo-003-06',
      instanceId: 'plant-003',
      assetPath: 'assets/placeholder/courgette_06.png',
      actionTag: ActionType.watered,
      takenAt: DateTime(2025, 4, 20),
      caption: 'Routine watering',
    ),
    PlantPhoto(
      photoId: 'photo-003-07',
      instanceId: 'plant-003',
      assetPath: 'assets/placeholder/courgette_07.png',
      actionTag: ActionType.repotted,
      takenAt: DateTime(2025, 3, 10),
      caption: 'Transplanted to raised bed',
    ),
  ];

  final Map<String, AIAnalysis> _analyses = {
    // Cherry Tomato – yellowing leaves (with progression)
    'photo-001-04': AIAnalysis(
      photoId: 'photo-001-04',
      conditionName: 'Nutrient Deficiency — Nitrogen',
      confidence: 0.87,
      analysisText:
          'The yellowing pattern on the lower leaves is consistent with '
          'nitrogen deficiency. The interveinal chlorosis starts at the leaf '
          'tips and progresses inward. Consider applying a balanced tomato '
          'fertiliser with higher nitrogen content.',
      progression: ProgressionComparison(
        previousPhotoId: 'photo-001-07',
        previousAssetPath: 'assets/placeholder/tomato_07.png',
        previousDate: DateTime(2025, 4, 5),
        currentAssetPath: 'assets/placeholder/tomato_04.png',
        currentDate: DateTime(2025, 5, 20),
        description:
            'Yellowing has spread from 2 lower leaves to 5 leaves over '
            '6 weeks. The condition is progressing — treatment is recommended.',
      ),
    ),
    // Cherry Tomato – early leaf curl (no progression, first occurrence)
    'photo-001-07': AIAnalysis(
      photoId: 'photo-001-07',
      conditionName: 'Leaf Curl — Environmental Stress',
      confidence: 0.72,
      analysisText:
          'Mild upward leaf curling detected, likely caused by temperature '
          'fluctuations or inconsistent watering. This is common in early '
          'spring and usually resolves as conditions stabilise.',
    ),
    // Basil – yellow lower leaves
    'photo-002-02': AIAnalysis(
      photoId: 'photo-002-02',
      conditionName: 'Overwatering Stress',
      confidence: 0.81,
      analysisText:
          'The lower leaves show yellowing and slight wilting consistent '
          'with overwatering. The soil appears waterlogged. Allow the top '
          'inch of soil to dry between waterings and ensure adequate drainage.',
    ),
    // Courgette – powdery mildew spreading (with progression)
    'photo-003-01': AIAnalysis(
      photoId: 'photo-003-01',
      conditionName: 'Powdery Mildew',
      confidence: 0.94,
      analysisText:
          'Significant powdery mildew coverage on upper leaf surfaces. '
          'The white fungal patches have expanded since the previous '
          'observation. Remove heavily affected leaves and apply a fungicidal '
          'spray. Improve air circulation around the plant.',
      progression: ProgressionComparison(
        previousPhotoId: 'photo-003-04',
        previousAssetPath: 'assets/placeholder/courgette_04.png',
        previousDate: DateTime(2025, 5, 18),
        currentAssetPath: 'assets/placeholder/courgette_01.png',
        currentDate: DateTime(2025, 6, 11),
        description:
            'Coverage has increased roughly 30% since 18 May. The mildew '
            'has spread from 3 leaves to most of the upper canopy.',
      ),
    ),
    // Courgette – first mildew signs (no progression, first occurrence)
    'photo-003-04': AIAnalysis(
      photoId: 'photo-003-04',
      conditionName: 'Powdery Mildew — Early Stage',
      confidence: 0.78,
      analysisText:
          'Small white patches detected on 3 leaves, consistent with early '
          'powdery mildew. Caught early, this can be managed by removing '
          'affected leaves and improving airflow.',
    ),
  };

  @override
  Future<List<PlantPhoto>> getPhotosForPlant(
    String instanceId, {
    String? tagFilter,
  }) async {
    var photos = _photos.where((p) => p.instanceId == instanceId);

    if (tagFilter != null) {
      final actionType = _tagFilterMap[tagFilter];
      if (actionType != null) {
        photos = photos.where((p) => p.actionTag == actionType);
      }
    }

    return photos.toList()..sort((a, b) => b.takenAt.compareTo(a.takenAt));
  }

  @override
  Future<PlantPhoto> getPhotoById(String photoId) async {
    return _photos.firstWhere(
      (p) => p.photoId == photoId,
      orElse: () => throw Exception('Photo not found: $photoId'),
    );
  }

  @override
  Future<AIAnalysis?> getAnalysisForPhoto(String photoId) async {
    return _analyses[photoId];
  }
}
