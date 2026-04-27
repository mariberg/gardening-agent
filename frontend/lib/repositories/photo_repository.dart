import '../models/plant_photo.dart';
import '../models/ai_analysis.dart';

abstract class PhotoRepository {
  Future<List<PlantPhoto>> getPhotosForPlant(String instanceId, {String? tagFilter});
  Future<PlantPhoto> getPhotoById(String photoId);
  Future<AIAnalysis?> getAnalysisForPhoto(String photoId);
}
