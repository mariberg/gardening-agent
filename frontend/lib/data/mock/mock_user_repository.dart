import '../../models/garden_statistics.dart';
import '../../models/user_profile.dart';
import '../../repositories/user_repository.dart';

class MockUserRepository implements UserRepository {
  @override
  Future<UserProfile> getUserProfile() async {
    return UserProfile(
      userId: 'user-001',
      name: 'Sarah Green',
      email: 'sarah@garden.app',
      location: 'London, UK',
      createdAt: DateTime(2024, 11, 1),
    );
  }

  @override
  Future<GardenStatistics> getGardenStatistics() async {
    return const GardenStatistics(
      totalPlants: 3,
      activeIssues: 1,
      totalActions: 12,
    );
  }

  @override
  Future<void> signOut() async {
    // No-op for mock implementation
  }
}
