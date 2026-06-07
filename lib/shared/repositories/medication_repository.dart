// ============================================
// FILE: medication_repository.dart
// PATH: lib/shared/repositories/medication_repository.dart
// LAYER: repository
// DOMAIN: medications
// RESPONSIBLE FOR: Reads medications from Hive first and syncs to Firestore in the background.
// RECEIVES: Auth UID (String), Medication model objects, and String IDs
// RETURNS: List<Medication>, Medication?, and void
// CONNECTS TO: medication.dart, app_exception.dart, hive_init_service.dart, connectivity_service.dart
// MUST NEVER: Import Flutter, call providers, or block the caller on network I/O
// EXPOSES:
//   Future<List<Medication>> getAll(String uid)
//   Future<Medication?> getById(String uid, String id)
//   Future<void> add(String uid, Medication medication)
//   Future<void> update(String uid, Medication medication)
//   Future<void> delete(String uid, String id)
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

import '../models/medication.dart';
import '../services/connectivity_service.dart';
import '../services/hive_init_service.dart';
import '../../core/errors/app_exception.dart';

// Internal key suffix for retry flag stored alongside a medication entry.
// Stored as a separate bool entry: '<id>__pendingSync' = true
const _pendingSuffix = '__pendingSync';

class MedicationRepository {
  MedicationRepository(this._firestore);

  final FirebaseFirestore _firestore;

  // ─── private helpers ──────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _firestore.collection('users').doc(uid).collection('medications');

  Box<Medication> get _box =>
      Hive.box<Medication>(HiveInitService.medicationsBox);

  // Hive keys are scoped per user: '<uid>/<id>'
  String _key(String uid, String id) => '$uid/$id';
  String _pendingKey(String uid, String id) => '$uid/$id$_pendingSuffix';

  bool _isPending(String uid, String id) =>
      (_box.get(_pendingKey(uid, id)) as dynamic) == true;

  Future<bool> get _isOnline => ConnectivityService.instance.isOnline;

  // ─── public interface ─────────────────────────────────────

  /// Returns cached medications immediately, then syncs from Firestore
  /// in the background if online. Subsequent reads will reflect updated data.
  Future<List<Medication>> getAll(String uid) async {
    try {
      // 1. Read cache immediately
      final cached = _box.keys
          .where(
            (k) =>
                k.toString().startsWith('$uid/') &&
                !k.toString().endsWith(_pendingSuffix),
          )
          .map((k) => _box.get(k))
          .whereType<Medication>()
          .toList();

      // 2. If cache is empty, await sync before returning
      //    (cold install / first login — nothing to show yet)
      if (cached.isEmpty) {
        await _syncAllFromFirestore(uid);
        return _box.keys
            .where(
              (k) =>
                  k.toString().startsWith('$uid/') &&
                  !k.toString().endsWith(_pendingSuffix),
            )
            .map((k) => _box.get(k))
            .whereType<Medication>()
            .toList();
      }

      // 3. Cache has data — return it immediately, sync in background
      _syncAllFromFirestore(uid);
      return cached;
    } catch (e) {
      throw AppException('Failed to fetch medications: $e');
    }
  }

  /// Returns cached medication immediately by ID.
  /// Returns null if not found locally.
  Future<Medication?> getById(String uid, String id) async {
    try {
      final cached = _box.get(_key(uid, id));

      // Background single-doc sync
      _syncOneFromFirestore(uid, id);

      return cached;
    } catch (e) {
      throw AppException('Failed to fetch medication $id: $e');
    }
  }

  /// Writes to Hive immediately and returns.
  /// Firestore write is attempted in the background.
  /// Sets a retry flag on the record if Firestore write fails.
  Future<void> add(String uid, Medication medication) async {
    try {
      await _box.put(_key(uid, medication.id), medication);
      _pushToFirestore(uid, medication);
    } catch (e) {
      throw AppException('Failed to add medication: $e');
    }
  }

  /// Same local-first pattern as add(). Last-write-wins.
  Future<void> update(String uid, Medication medication) async {
    try {
      await _box.put(_key(uid, medication.id), medication);
      _pushToFirestore(uid, medication);
    } catch (e) {
      throw AppException('Failed to update medication ${medication.id}: $e');
    }
  }

  /// Deletes from Hive immediately.
  /// Firestore delete is attempted in the background.
  Future<void> delete(String uid, String id) async {
    try {
      await _box.delete(_key(uid, id));
      await _box.delete(_pendingKey(uid, id)); // clear any retry flag
      _deleteFromFirestore(uid, id);
    } catch (e) {
      throw AppException('Failed to delete medication $id: $e');
    }
  }

  // ─── background sync helpers ──────────────────────────────

  /// Fetches all medications from Firestore and overwrites Hive (last-write-wins).
  Future<void> _syncAllFromFirestore(String uid) async {
    if (!await _isOnline) return;
    try {
      final snapshot = await _collection(uid).get();
      for (final doc in snapshot.docs) {
        final medication = Medication.fromMap(doc.data());
        await _box.put(_key(uid, medication.id), medication);
        await _box.delete(_pendingKey(uid, medication.id)); // clear retry flag
      }
    } catch (_) {
      // Silent — caller already has cached data
    }
  }

  /// Fetches a single document from Firestore and overwrites Hive.
  Future<void> _syncOneFromFirestore(String uid, String id) async {
    if (!await _isOnline) return;
    try {
      final doc = await _collection(uid).doc(id).get();
      if (!doc.exists || doc.data() == null) return;
      final medication = Medication.fromMap(doc.data()!);
      await _box.put(_key(uid, id), medication);
      await _box.delete(_pendingKey(uid, id));
    } catch (_) {
      // Silent
    }
  }

  /// Pushes a medication to Firestore. Sets retry flag on failure.
  Future<void> _pushToFirestore(String uid, Medication medication) async {
    if (!await _isOnline) {
      // Mark for retry — no crash, no queue
      await _box.put(_pendingKey(uid, medication.id), true as dynamic);
      return;
    }
    try {
      await _collection(uid).doc(medication.id).set(medication.toMap());
      await _box.delete(_pendingKey(uid, medication.id)); // clear on success
    } catch (_) {
      await _box.put(_pendingKey(uid, medication.id), true as dynamic);
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
