// ============================================
// FILE: notification_scheduler_service_provider.dart
// LAYER: service
// DOMAIN: shared
// ============================================

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'medication_service_provider.dart';
import 'notification_service.dart';
import 'notification_scheduler_service.dart';

part 'notification_scheduler_service_provider.g.dart';

@riverpod
NotificationSchedulerService notificationSchedulerService(Ref ref) {
  return NotificationSchedulerService(
    notificationService: NotificationService.instance,
    medicationService: ref.read(medicationServiceProvider),
  );
}
