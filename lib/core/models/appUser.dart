import 'package:uuid/uuid.dart';

class AppUser {
  const AppUser({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.createdAt,
  });

  factory AppUser.guest() {
    return AppUser(
      userId: const Uuid().v4(),
      displayName: '게스트',
      email: '',
      avatarUrl: '',
      createdAt: DateTime.now(),
    );
  }

  final String userId;
  final String displayName;
  final String email;
  final String avatarUrl;
  final DateTime createdAt;
}
