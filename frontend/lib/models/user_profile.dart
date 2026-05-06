class UserProfile {
  final String userId;
  final String name;
  final String email;
  final String location;
  final DateTime createdAt;

  const UserProfile({
    required this.userId,
    required this.name,
    required this.email,
    required this.location,
    required this.createdAt,
  });
}
