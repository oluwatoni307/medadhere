import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/repositories/auth_repository.dart';
import '../../auth/state/auth_notifier_provider.dart';

part 'user_profile_notifier.g.dart';

// PATH: lib/features/onboarding/state/user_profile_notifier.dart
// DOMAIN: features
// LAYER: state
// RESPONSIBLE FOR: Reads user document from Firestore and exposes name write method for welcome screen

@riverpod
class UserProfileNotifier extends _$UserProfileNotifier {
  // Instantiated with the proper core Firestore instance dependency
  final AuthRepository _repository = AuthRepository(FirebaseFirestore.instance);

  @override
  Future<AppUser?> build() async {
    // Watch the auth stream provider safely
    final authAsyncValue = ref.watch(authProvider);

    // Extract the authenticated AppUser from the AsyncValue stream container
    final AppUser? authUser = authAsyncValue.value;

    if (authUser == null || authUser.uid.isEmpty) {
      return null;
    }

    // Pure data fetch cleanly delegated to the repository layer
    return await _repository.getUserDocument(authUser.uid);
  }

  Future<void> writeName(String displayName) async {
    final String trimmedName = displayName.trim();

    if (trimmedName.isEmpty) {
      throw ArgumentError('Display name cannot be empty.');
    }

    final authAsyncValue = ref.read(authProvider);
    final AppUser? authUser = authAsyncValue.value;

    if (authUser == null || authUser.uid.isEmpty) {
      throw StateError(
        'Cannot write name: No authenticated user session found.',
      );
    }

    // 1. Direct database write
    await _repository.updateDisplayName(authUser.uid, trimmedName);

    // 2. CRITICAL FIX: Check if Riverpod rebuilt this provider during the database write
    if (!ref.mounted) return;

    // 3. Fetch the updated document directly
    final updatedUser = await _repository.getUserDocument(authUser.uid);

    // 4. CRITICAL FIX: Check again before touching the state
    if (!ref.mounted) return;

    // 5. Update the state locally
    if (updatedUser != null) {
      state = AsyncData(updatedUser);
    }
  }
}
