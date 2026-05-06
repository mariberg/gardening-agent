import '../models/user_profile.dart';
import '../models/garden_statistics.dart';

abstract class UserRepository {
  Future<UserProfile> getUserProfile();
  Future<GardenStatistics> getGardenStatistics();
  Future<void> signOut();
}
