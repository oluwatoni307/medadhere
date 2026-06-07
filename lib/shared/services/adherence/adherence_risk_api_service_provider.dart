// ============================================
// FILE: adherence_risk_api_service_provider.dart
// LAYER: service
// DOMAIN: adherence
// RESPONSIBLE FOR: Provides AdherenceRiskApiService to the Riverpod graph
// RECEIVES: nothing
// RETURNS: AdherenceRiskApiService instance
// CONNECTS TO: adherence_risk_api_service.dart
// MUST NEVER: instantiate repositories or import Flutter
// ============================================

// EXPOSES: adherenceRiskApiServiceProvider

// flutter — none
// packages
import 'package:riverpod_annotation/riverpod_annotation.dart';
// internal — services
import 'adherence_risk_api_service.dart';

part 'adherence_risk_api_service_provider.g.dart';

@riverpod
AdherenceRiskApiService adherenceRiskApiService(Ref ref) {
  return AdherenceRiskApiService();
}
