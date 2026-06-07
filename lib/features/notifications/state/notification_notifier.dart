// ============================================
// FILE: notification_notifier.dart
// PATH: lib/features/notifications/state/notification_notifier.dart
// LAYER: state
// DOMAIN: features
// RESPONSIBLE FOR: Exposes notification permission state for UI consumption.
// MUST NEVER: Contain scheduling logic (moved to NotificationSchedulerService)
// ============================================

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/services/notification_service.dart';

part 'notification_notifier.g.dart';

@riverpod
class NotificationNotifier extends _$NotificationNotifier {
  final NotificationService _notificationService = NotificationService.instance;

  @override
  bool build() => _notificationService.permissionGranted;

  /// Call this after the user returns from system settings
  /// or after init() completes to refresh the flag.
  void refresh() {
    state = _notificationService.permissionGranted;
  }
}
