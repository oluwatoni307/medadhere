// ============================================
// FILE: notification_payload.dart
// PATH: lib/shared/models/notification_payload.dart
// LAYER: model
// DOMAIN: shared
// RESPONSIBLE FOR: Pure data container for notification payload — serialises to and from JSON string for log-dose navigation.
// RECEIVES: JSON string or constructor arguments
// RETURNS: NotificationPayload object, Map<String, dynamic>, or JSON string
// CONNECTS TO: NotificationService (payload encoding), log-dose route (payload decoding)
// MUST NEVER: Contain business logic, UI imports, or Flutter framework imports
// ============================================

import 'dart:convert';

class NotificationPayload {
  const NotificationPayload({
    required this.medicationId,
    required this.medicationName,
    required this.doseAmount,
    required this.scheduleLabel,
    required this.scheduleId,
    required this.scheduledTimeMs,
  });

  final String medicationId;
  final String medicationName;
  final String doseAmount;
  final String scheduleLabel;
  final String scheduleId;
  final int scheduledTimeMs;

  // ─── serialisation ────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'medicationId': medicationId,
    'medicationName': medicationName,
    'doseAmount': doseAmount,
    'scheduleLabel': scheduleLabel,
    'scheduleId': scheduleId,
    'scheduledTimeMs': scheduledTimeMs,
  };

  String toPayload() => jsonEncode(toJson());

  // ─── deserialisation ──────────────────────────────────────

  factory NotificationPayload.fromPayload(String payload) {
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;

      _requireString(map, 'medicationId');
      _requireString(map, 'medicationName');
      _requireString(map, 'doseAmount');
      _requireString(map, 'scheduleLabel');
      _requireString(map, 'scheduleId');
      _requireNum(map, 'scheduledTimeMs');

      return NotificationPayload(
        medicationId: map['medicationId'] as String,
        medicationName: map['medicationName'] as String,
        doseAmount: map['doseAmount'] as String,
        scheduleLabel: map['scheduleLabel'] as String,
        scheduleId: map['scheduleId'] as String,
        scheduledTimeMs: (map['scheduledTimeMs'] as num).toInt(),
      );
    } on FormatException {
      rethrow; // preserve descriptive FormatExceptions from validators
    } catch (_) {
      throw FormatException(
        'NotificationPayload: payload is not valid JSON — "$payload"',
      );
    }
  }

  // ─── private helpers ──────────────────────────────────────

  static void _requireString(Map<String, dynamic> map, String key) {
    if (!map.containsKey(key) || map[key] == null) {
      throw FormatException(
        'NotificationPayload: required field "$key" is missing or null',
      );
    }
    if (map[key] is! String) {
      throw FormatException(
        'NotificationPayload: field "$key" must be a String, got ${map[key].runtimeType}',
      );
    }
  }

  static void _requireNum(Map<String, dynamic> map, String key) {
    if (!map.containsKey(key) || map[key] == null) {
      throw FormatException(
        'NotificationPayload: required field "$key" is missing or null',
      );
    }
    if (map[key] is! num) {
      throw FormatException(
        'NotificationPayload: field "$key" must be a num, got ${map[key].runtimeType}',
      );
    }
  }
}
