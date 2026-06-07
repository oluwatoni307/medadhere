// ============================================
// FILE: adherence_feature_service_provider.dart
// LAYER: service
// DOMAIN: adherence
// RESPONSIBLE FOR: Provides AdherenceFeatureService to the Riverpod graph
// RECEIVES: nothing
// RETURNS: AdherenceFeatureService instance
// CONNECTS TO: adherence_feature_service.dart, dose_log_repository.dart, medication_repository.dart
// MUST NEVER: instantiate repositories anywhere other than here
// ============================================

// EXPOSES: adherenceFeatureServiceProvider

// flutter — none
// packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
// internal — services
import 'adherence_feature_service.dart';
// internal — repositories
import '../../repositories/dose_log_repository.dart';
import '../../repositories/medication_repository.dart';

part 'adherence_feature_service_provider.g.dart';

@riverpod
AdherenceFeatureService adherenceFeatureService(Ref ref) {
  return AdherenceFeatureService(
    doseLogRepository: DoseLogRepository(FirebaseFirestore.instance),
    medicationRepository: MedicationRepository(FirebaseFirestore.instance),
  );
}
