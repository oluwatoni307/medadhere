// ===
// FILE: auth_repository.dart
// LAYER: repository
// DOMAIN: shared
// RESPONSIBLE FOR: Reads and writes the user document in Firestore, returning clean AppUser models
// RECEIVES: AppUser (on write), uid String (on read)
// RETURNS: Future<void> on write, Future<AppUser?> on read
// CONNECTS TO: lib/shared/models/app_user.dart
// MUST NEVER: import Firebase Auth, Riverpod, or any Flutter UI primitive.
//             Must never return a raw Firestore document or throw on missing documents.
// ===

// flutter
// [intentionally blank]

// packages
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

//
// --- repository ---
//

class AuthRepository {
  const AuthRepository(this._firestore);

  final FirebaseFirestore _firestore;

  //
  // --- write ---
  //

  Future<void> createUserDocument(AppUser user) async {
    final Map<String, dynamic> data = {
      'uid': user.uid,
      'email': user.email,
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Safely add displayName if it exists
    if (user.displayName != null) {
      data['displayName'] = user.displayName;
    }

    // Using merge: true prevents accidental overwrites if the doc already exists
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(data, SetOptions(merge: true));
  }

  //
  // --- update ---
  //

  Future<void> updateDisplayName(String uid, String displayName) async {
    await _firestore.collection('users').doc(uid).update({
      'displayName': displayName,
    });
  }

  //
  // --- read ---
  //

  Future<AppUser?> getUserDocument(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists) return null;

    final data = doc.data()!;

    return AppUser(
      uid: data['uid'] as String,
      email: data['email'] as String,
      createdAt: (data['createdAt'] as Timestamp?)!.toDate(),
      displayName: data['displayName'] as String?, // Nullable cast for safety
    );
  }
}
