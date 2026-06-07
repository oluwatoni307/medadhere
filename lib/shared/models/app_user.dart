// PATH: lib/shared/models/app_user.dart
// DOMAIN: shared
// LAYER: model
// RESPONSIBLE FOR: Pure data container holding all fields that represent an authenticated user — patched to include displayName

class AppUser {
  final String uid;
  final String email;
  final DateTime? createdAt;
  final String? displayName;

  const AppUser({
    required this.uid,
    required this.email,
    required this.createdAt,
    this.displayName,
  });
}
