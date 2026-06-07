//============================================
//FILE: app_exception.dart
//LAYER: core
//DOMAIN: core
//RESPONSIBLE FOR: Typed application exception for domain-level error handling.
//RECEIVES: Error message
//RETURNS: Exception object
//CONNECTS TO: Nothing
//MUST NEVER: Contain business logic
//============================================

class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => 'AppException: $message';
}
