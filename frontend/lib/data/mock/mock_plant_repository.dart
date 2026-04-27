import '../../models/plant_instance.dart';
import '../../repositories/plant_repository.dart';

class MockPlantRepository implements PlantRepository {
  final List<PlantInstance> _plants = [
    PlantInstance(
      instanceId: 'plant-001',
      speciesId: 'species-tomato',
      nickname: 'Cherry Tomato',
      emoji: '🍅',
      gardenLocation: 'Raised bed A',
      plantedAt: DateTime(2025, 3, 15),
      status: PlantStatus.thriving,
      statusLabel: 'Thriving',
      nextWateringDate: DateTime.now().add(const Duration(days: 1)),
      sunRequirement: 'Full sun',
      speciesCommonName: 'Cherry Tomato',
      speciesLatinName: 'Solanum lycopersicum var. cerasiforme',
      aiInsightText:
          'Your Cherry Tomato is doing great! The recent warm spell has '
          'boosted growth. Consider adding a light feed of tomato fertiliser '
          'this week to support the new fruit clusters forming.',
    ),
    PlantInstance(
      instanceId: 'plant-002',
      speciesId: 'species-basil',
      nickname: 'Basil',
      emoji: '🌿',
      gardenLocation: 'Herb planter',
      plantedAt: DateTime(2025, 4, 2),
      status: PlantStatus.needsAttention,
      statusLabel: 'Needs attention',
      nextWateringDate: DateTime.now(),
      sunRequirement: 'Partial shade',
      speciesCommonName: 'Sweet Basil',
      speciesLatinName: 'Ocimum basilicum',
      aiInsightText:
          'Your Basil is showing early signs of overwatering — the lower '
          'leaves are slightly yellow. Let the soil dry out before the next '
          'watering and ensure the planter has good drainage.',
    ),
    PlantInstance(
      instanceId: 'plant-003',
      speciesId: 'species-courgette',
      nickname: 'Courgette',
      emoji: '🥒',
      gardenLocation: 'Raised bed B',
      plantedAt: DateTime(2025, 2, 28),
      status: PlantStatus.alert,
      statusLabel: 'Mildew alert',
      nextWateringDate: DateTime.now().subtract(const Duration(days: 1)),
      sunRequirement: 'Full sun',
      speciesCommonName: 'Courgette',
      speciesLatinName: 'Cucurbita pepo',
      aiInsightText:
          'Powdery mildew has been detected on several leaves. Remove '
          'affected foliage promptly and improve air circulation around the '
          'plant. A diluted milk spray can help prevent further spread.',
    ),
  ];

  @override
  Future<PlantInstance> getPlantById(String instanceId) async {
    return _plants.firstWhere(
      (p) => p.instanceId == instanceId,
      orElse: () => throw Exception('Plant not found: $instanceId'),
    );
  }

  @override
  Future<List<PlantInstance>> getAllPlants() async {
    return List.unmodifiable(_plants);
  }
}
