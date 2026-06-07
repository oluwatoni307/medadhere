// ===
// FILE: auth_service.dart
// LAYER: service
// DOMAIN: shared
// RESPONSIBLE FOR: Wraps all Firebase Auth operations and delegates Firestore user
//                  document creation to AuthRepository on first registration
// RECEIVES: email (String), password (String) per operation
// RETURNS: AppUser on register/signIn, void on signOut/passwordReset
// CONNECTS TO: lib/shared/models/app_user.dart
//              lib/shared/repositories/auth_repository.dart
// MUST NEVER: return raw Firebase objects, import Riverpod or Flutter UI primitives,
//             swallow FirebaseAuthException, or accept AuthRepository via injection
// ===

// flutter
// [intentionally blank]

// packages
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../repositories/auth_repository.dart';

//
// --- service ---
//

class AuthService {
  AuthService() : _auth = FirebaseAuth.instance;

  final FirebaseAuth _auth;
  final AuthRepository _repository = AuthRepository(FirebaseFirestore.instance);

  //
  // --- register ---
  //

  Future<AppUser> register({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user!;
    final appUser = _mapToAppUser(user);

    if (credential.additionalUserInfo?.isNewUser == true) {
      await _repository.createUserDocument(appUser);
    }

    return appUser;
  }

  //
  // --- sign in ---
  //

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return _mapToAppUser(credential.user!);
  }

  //
  // --- sign out ---
  //

  Future<void> signOut() async {
    await _auth.signOut();
  }

  //
  // --- password reset ---
  //

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  //
  // --- stream ---
  //
  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().map(
      (user) => user == null ? null : _mapToAppUser(user),
    );
  }

  //
  // --- internal mapping ---
  //

  AppUser _mapToAppUser(User user) {
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      // Safely extract creation time, fallback to now if somehow null
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      // Extract the new displayName property
      displayName: user.displayName,
    );
  }
}
