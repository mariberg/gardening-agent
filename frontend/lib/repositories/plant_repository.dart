import '../models/plant_instance.dart';

abstract class PlantRepository {
  Future<PlantInstance> getPlantById(String instanceId);
  Future<List<PlantInstance>> getAllPlants();
}
