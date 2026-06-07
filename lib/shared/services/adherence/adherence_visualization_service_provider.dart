// ============================================
// FILE: adherence_visualization_service_provider.dart
// LAYER: service
// DOMAIN: adherence
// RESPONSIBLE FOR: Riverpod provider exposing AdherenceVisualizationService for injection
// RECEIVES: Ref — reads medicationServiceProvider and doseLogServiceProvider
// RETURNS: AdherenceVisualizationService instance
// CONNECTS TO: adherence_visualization_service.dart,
//              medication_service_provider.dart,
//              dose_log_service_provider.dart
// MUST NEVER: contain UI code, business logic, or call Firestore directly beyond instantiation
// ============================================

// packages
import 'package:riverpod_annotation/riverpod_annotation.dart';

// internal — services
import '../medication_service_provider.dart';
import '../dose_log_service_provider.dart';
import 'adherence_visualization_service.dart';

part 'adherence_visualization_service_provider.g.dart';

@riverpod
AdherenceVisualizationService adherenceVisualizationService(Ref ref) {
  return AdherenceVisualizationService(
    medicationService: ref.read(medicationServiceProvider),
    doseLogService: ref.read(doseLogServiceProvider),
  );
}
