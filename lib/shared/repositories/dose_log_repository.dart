// ============================================
// FILE: dose_log_repository.dart
// PATH: lib/shared/repositories/dose_log_repository.dart
// LAYER: repository
// DOMAIN: dose_logging
// RESPONSIBLE FOR: Reads dose logs from Hive first, syncs Firestore in background.
// RECEIVES: Auth UID (String), DoseLog model objects, String IDs, DateTime range parameters
// RETURNS: List<DoseLog> and void
// CONNECTS TO: dose_log.dart, app_exception.dart, hive_init_service.dart, connectivity_service.dart
// MUST NEVER: import Flutter, call services or providers, block the caller on network I/O
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

import '../models/dose_log.dart';
import '../services/connectivity_service.dart';
import '../services/hive_init_service.dart';
import '../../core/errors/app_exception.dart';

const _pendingSuffix = '__pendingSync';

class DoseLogRepository {
  DoseLogRepository(this._firestore);

  final FirebaseFirestore _firestore;

  // ─── private helpers ──────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _firestore.collection('users').doc(uid).collection('dose_logs');

  Box<DoseLog> get _box => Hive.box<DoseLog>(HiveInitService.doseLogsBox);

  String _key(String uid, String id) => '$uid/$id';
  String _pendingKey(String uid, String id) => '$uid/$id$_pendingSuffix';

  Future<bool> get _isOnline => ConnectivityService.instance.isOnline;

  List<DoseLog> _allCached(String uid) => _box.keys
      .where(
        (k) =>
            k.toString().startsWith('$uid/') &&
            !k.toString().endsWith(_pendingSuffix),
      )
      .map((k) => _box.get(k))
      .whereType<DoseLog>()
      .toList();

  // ─── public interface ─────────────────────────────────────

  Future<List<DoseLog>> getAll(String uid) async {
    try {
      final cached = _allCached(uid);
      _syncAllFromFirestore(uid);
      return cached;
    } catch (e) {
      throw AppException('Failed to fetch dose logs: $e');
    }
  }

  Future<List<DoseLog>> getByMedicationId(
    String uid,
    String medicationId,
  ) async {
    try {
      final cached = _allCached(
        uid,
      ).where((l) => l.medicationId == medicationId).toList();
      _syncAllFromFirestore(uid);
      return cached;
    } catch (e) {
      throw AppException(
        'Failed to fetch logs for medication $medicationId: $e',
      );
    }
  }

  // Date range filter is done in-memory from cache —
  // Hive does not support range queries natively.
  // Background sync keeps the cache fresh so this stays accurate.
  Future<List<DoseLog>> getByDateRange(
    String uid,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final cached = _allCached(uid)
          .where(
            (l) =>
                !l.scheduledTime.isBefore(start) &&
                !l.scheduledTime.isAfter(end),
          )
          .toList();
      _syncAllFromFirestore(uid);
      return cached;
    } catch (e) {
      throw AppException('Failed to fetch logs for date range: $e');
    }
  }

  Future<void> add(String uid, DoseLog log) async {
    try {
      await _box.put(_key(uid, log.id), log);
      _pushToFirestore(uid, log);
    } catch (e) {
      throw AppException('Failed to add dose log: $e');
    }
  }

  Future<void> delete(String uid, String id) async {
    try {
      await _box.delete(_key(uid, id));
      await _box.delete(_pendingKey(uid, id));
      _deleteFromFirestore(uid, id);
    } catch (e) {
      throw AppException('Failed to delete dose log $id: $e');
    }
  }

  // ─── background sync helpers ──────────────────────────────

  Future<void> _syncAllFromFirestore(String uid) async {
    if (!await _isOnline) return;
    try {
      final snapshot = await _collection(uid).get();
      for (final doc in snapshot.docs) {
        final log = DoseLog.fromMap(doc.data());
        await _box.put(_key(uid, log.id), log);
        await _box.delete(_pendingKey(uid, log.id));
      }
    } catch (_) {
      // Silent — caller already has cached data
    }
  }

  Future<void> _pushToFirestore(String uid, DoseLog log) async {
    if (!await _isOnline) {
      await _box.put(_pendingKey(uid, log.id), true as dynamic);
      return;
    }
    try {
      await _collection(uid).doc(log.id).set(log.toMap());
      await _box.delete(_pendingKey(uid, log.id));
    } catch (_) {
      await _box.put(_pendingKey(uid, log.id), true as dynamic);
    }
  }

  Future<void> _deleteFromFirestore(String uid, String id) async {
    if (!await _isOnline) return;
    try {
      await _collection(uid).doc(id).delete();
    } catch (_) {
      // Silent
    }
  }
}
