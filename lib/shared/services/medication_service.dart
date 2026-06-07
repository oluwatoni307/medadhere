// ============================================
// FILE: medication_service.dart
// LAYER: service
// DOMAIN: medications
// RESPONSIBLE FOR: All medication business logic — fetch, add, edit, delete.
// RECEIVES: Auth UID (String), Medication objects and IDs
// RETURNS: Future<List<Medication>>, Future<Medication>, Future<void>
// CONNECTS TO: medication_repository.dart, app_exception.dart
// MUST NEVER: Call Firestore directly or contain UI code
// ============================================

// internal — models
import '../models/medication.dart';

// internal — repositories
import '../repositories/medication_repository.dart';

// internal — core
import '../../core/errors/app_exception.dart';

class MedicationService {
  const MedicationService(this._repository);

  final MedicationRepository _repository;

  Future<List<Medication>> getMedications(String uid) async {
    try {
      return await _repository.getAll(uid);
    } catch (e) {
      throw AppException('Failed to load medications: $e');
    }
  }

  Future<Medication> getMedicationById(String uid, String id) async {
    try {
      final medication = await _repository.getById(uid, id);
      if (medication == null) {
        throw const AppException('Medication not found');
      }
      return medication;
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to load medication: $e');
    }
  }

  Future<void> addMedication(String uid, Medication medication) async {
    try {
      await _repository.add(uid, medication);
    } catch (e) {
      throw AppException('Failed to add medication: $e');
    }
  }

  Future<void> updateMedication(String uid, Medication medication) async {
    try {
      await _repository.update(uid, medication);
    } catch (e) {
      throw AppException('Failed to update medication: $e');
    }
  }

  Future<void> deleteMedication(String uid, String id) async {
    try {
      await _repository.delete(uid, id);
    } catch (e) {
      throw AppException('Failed to delete medication: $e');
    }
  }
}
