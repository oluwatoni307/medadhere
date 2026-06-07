//============================================
//FILE: dose_log_service_provider.dart
//LAYER: service
//DOMAIN: dose_logging
//RESPONSIBLE FOR: Riverpod provider exposing DoseLogService for injection
//RECEIVES: Nothing
//RETURNS: DoseLogService instance
//CONNECTS TO: dose_log_repository.dart, dose_log_service.dart
//MUST NEVER: Contain UI code or business logic
//============================================

// packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// internal — repositories
import '../repositories/dose_log_repository.dart';

// internal — services
import 'dose_log_service.dart';

part 'dose_log_service_provider.g.dart';

@riverpod
DoseLogService doseLogService(Ref ref) {
  return DoseLogService(DoseLogRepository(FirebaseFirestore.instance));
}
