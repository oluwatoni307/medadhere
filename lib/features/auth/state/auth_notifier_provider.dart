// ===
// FILE: auth_notifier_provider.dart
// LAYER: state
// DOMAIN: auth
// RESPONSIBLE FOR: Owns auth state stream, exposes current AppUser or null, and
//                 provides register, sign in, sign out, and password reset methods
// RECEIVES: No external Riverpod ref dependencies — AuthService owned internally
// RETURNS: AsyncValue<AppUser?>
// CONNECTS TO: lib/shared/models/app_user.dart
//              lib/shared/services/auth_service.dart
// MUST NEVER: Hold UI layout primitives, make direct repository requests, import
//             Flutter UI layer, or register AuthService as a provider
// ===

// flutter
// [intentionally blank]

// packages
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/models/app_user.dart';
import '../../../shared/services/auth_service.dart';

part 'auth_notifier_provider.g.dart';

//
// --- notifier ---
//

@riverpod
class AuthNotifier extends _$AuthNotifier {
  final AuthService _authService = AuthService();

  @override
  Stream<AppUser?> build() {
    return _authService.authStateChanges();
  }

  //
  // --- public methods ---
  //

  Future<void> register({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      await _authService.register(email: email, password: password);
    } on FirebaseAuthException catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      await _authService.signIn(email: email, password: password);
    } on FirebaseAuthException catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    state = const AsyncLoading();
    try {
      await _authService.sendPasswordReset(email);
    } on FirebaseAuthException catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
