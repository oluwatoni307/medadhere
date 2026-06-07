//============================================
//FILE: medication_service_provider.dart
//LAYER: service
//DOMAIN: medications
//RESPONSIBLE FOR: Riverpod provider exposing MedicationService for injection.
//RECEIVES: Nothing
//RETURNS: MedicationService instance
//CONNECTS TO: medication_repository.dart, medication_service.dart
//MUST NEVER: Contain UI code or business logic
//============================================

// packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// internal — repositories
import '../repositories/medication_repository.dart';

// internal — services
import 'medication_service.dart';

part 'medication_service_provider.g.dart';

@riverpod
MedicationService medicationService(Ref ref) {
  return MedicationService(MedicationRepository(FirebaseFirestore.instance));
}
