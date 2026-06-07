// ============================================
// FILE: adherence_visualization_provider.dart
// LAYER: state
// DOMAIN: adherence
// RESPONSIBLE FOR: Three async providers — one per visualization view.
//                  strip (7-day), month (30-day), trend (90-day).
// RECEIVES: nothing — reads from adherenceVisualizationServiceProvider
// RETURNS: Future<AdherenceStripData>, Future<AdherenceMonthData>,
//          Future<AdherenceTrendData>
// CONNECTS TO: adherence_visualization_service_provider.dart,
//              adherence_visualization_models.dart,
//              auth_notifier_provider.dart
// MUST NEVER: import Flutter widgets, call Firestore directly,
//             contain computation logic, or expose raw DoseLog data to UI
// ============================================

// packages
import 'package:riverpod_annotation/riverpod_annotation.dart';

// internal — models
import '../../../shared/models/adherence_visualization_models.dart';

// internal — service provider
import '../../../shared/services/adherence/adherence_visualization_service_provider.dart';

// internal — auth
import 'package:medadhere/features/auth/state/auth_notifier_provider.dart';

part 'adherence_visualization_provider.g.dart';

/// 7-day strip — per medication statuses sorted by priority.
/// Invalidate when a new dose is logged.
@riverpod
Future<AdherenceStripData> adherenceStrip(Ref ref) async {
  final user = await ref.watch(authProvider.future);
  if (user == null) return AdherenceStripData.empty();

  final service = ref.watch(adherenceVisualizationServiceProvider);
  return service.getStripData(user.uid);
}

/// 30-day line chart — aggregate daily completion rates.
/// Slower-changing — does not need to invalidate on every dose log.
@riverpod
Future<AdherenceMonthData> adherenceMonth(Ref ref) async {
  final user = await ref.watch(authProvider.future);
  if (user == null) return AdherenceMonthData.empty();

  final service = ref.watch(adherenceVisualizationServiceProvider);
  return service.getMonthData(user.uid);
}

/// 90-day bar chart — aggregate weekly completion rates and trend direction.
/// Slowest-changing — invalidate daily or on explicit refresh only.
@riverpod
Future<AdherenceTrendData> adherenceTrend(Ref ref) async {
  final user = await ref.watch(authProvider.future);
  if (user == null) return AdherenceTrendData.empty();

  final service = ref.watch(adherenceVisualizationServiceProvider);
  return service.getTrendData(user.uid);
}
