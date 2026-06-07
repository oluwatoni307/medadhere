// ============================================
// FILE: category_repository.dart
// PATH: lib/shared/repositories/category_repository.dart
// LAYER: repository
// DOMAIN: medications
// RESPONSIBLE FOR: Reads categories from Hive first and syncs to Firestore in the background.
// RECEIVES: Auth UID (String), Category model objects, and String IDs
// RETURNS: List<Category> and void
// CONNECTS TO: category.dart, app_exception.dart, hive_init_service.dart, connectivity_service.dart
// MUST NEVER: Import Flutter, call providers, or block the caller on network I/O
// EXPOSES:
//   Future<List<Category>> getAll(String uid)
//   Future<void> add(String uid, Category category)
//   Future<void> delete(String uid, String id)
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

import '../models/category.dart';
import '../services/connectivity_service.dart';
import '../services/hive_init_service.dart';
import '../../core/errors/app_exception.dart';

const _pendingSuffix = '__pendingSync';

class CategoryRepository {
  CategoryRepository(this._firestore);

  final FirebaseFirestore _firestore;

  // ─── private helpers ──────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _firestore.collection('users').doc(uid).collection('categories');

  Box<Category> get _box => Hive.box<Category>(HiveInitService.categoriesBox);

  String _key(String uid, String id) => '$uid/$id';
  String _pendingKey(String uid, String id) => '$uid/$id$_pendingSuffix';

  Future<bool> get _isOnline => ConnectivityService.instance.isOnline;

  List<Category> _cachedForUser(String uid) => _box.keys
      .where(
        (k) =>
            k.toString().startsWith('$uid/') &&
            !k.toString().endsWith(_pendingSuffix),
      )
      .map((k) => _box.get(k))
      .whereType<Category>()
      .toList();

  // ─── public interface ─────────────────────────────────────

  /// Returns all cached categories immediately, then syncs from Firestore
  /// in the background if online.
  Future<List<Category>> getAll(String uid) async {
    try {
      final cached = _cachedForUser(uid);
      _syncAllFromFirestore(uid);
      return cached;
    } catch (e) {
      throw AppException('Failed to fetch categories: $e');
    }
  }

  /// Writes to Hive immediately and returns.
  /// Firestore write is attempted in the background.
  /// Sets a retry flag on the record if offline or Firestore write fails.
  Future<void> add(String uid, Category category) async {
    try {
      await _box.put(_key(uid, category.id), category);
      _pushToFirestore(uid, category);
    } catch (e) {
      throw AppException('Failed to add category: $e');
    }
  }

  /// Deletes from Hive immediately.
  /// Firestore delete is attempted in the background.
  Future<void> delete(String uid, String id) async {
    try {
      await _box.delete(_key(uid, id));
      await _box.delete(_pendingKey(uid, id));
      _deleteFromFirestore(uid, id);
    } catch (e) {
      throw AppException('Failed to delete category $id: $e');
    }
  }

  // ─── background sync helpers ──────────────────────────────

  /// Fetches all categories from Firestore and overwrites Hive (last-write-wins).
  Future<void> _syncAllFromFirestore(String uid) async {
    if (!await _isOnline) return;
    try {
      final snapshot = await _collection(uid).get();
      for (final doc in snapshot.docs) {
        final category = Category.fromMap(doc.data());
        await _box.put(_key(uid, category.id), category);
        await _box.delete(_pendingKey(uid, category.id));
      }
    } catch (_) {
      // Silent — caller already has cached data
    }
  }

  /// Pushes a category to Firestore. Sets retry flag on failure or offline.
  Future<void> _pushToFirestore(String uid, Category category) async {
    if (!await _isOnline) {
      await _box.put(_pendingKey(uid, category.id), true as dynamic);
      return;
    }
    try {
      await _collection(uid).doc(category.id).set(category.toMap());
      await _box.delete(_pendingKey(uid, category.id));
    } catch (_) {
      await _box.put(_pendingKey(uid, category.id), true as dynamic);
    }
  }

  /// Deletes a document from Firestore in the background.
  Future<void> _deleteFromFirestore(String uid, String id) async {
    if (!await _isOnline) return;
    try {
      await _collection(uid).doc(id).delete();
    } catch (_) {
      // Silent — local delete already committed
    }
  }
}
