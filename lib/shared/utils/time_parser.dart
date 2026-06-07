// ============================================
// FILE: time_parser.dart
// LAYER: logic
// DOMAIN: core
// RESPONSIBLE FOR: Parsing time strings into DateTime objects and building schedule label strings
// RECEIVES: Time strings in HH:mm or h:mm AM/PM format, a reference DateTime, and a frequency string
// RETURNS: DateTime? and String
// CONNECTS TO: nothing
// MUST NEVER: import Flutter, throw on malformed input, depend on any app layer
// EXPOSES:
//   DateTime? parseTimeString(String timeStr, DateTime now)
//   DateTime? nextOccurrence(String timeStr, DateTime now)
//   String buildScheduleLabel(String timeStr, String frequency)
// ============================================

class TimeParser {
  TimeParser._();

  // --- public methods ---

  /// Parses [timeStr] into a DateTime on the same date as [now].
  ///
  /// Always returns today's date regardless of whether the time has passed.
  /// Returns null if [timeStr] cannot be parsed.
  static DateTime? parseTimeString(String timeStr, DateTime now) {
    try {
      final trimmed = timeStr.trim();
      if (_is24Hour(trimmed)) return _parse24Hour(trimmed, now);
      if (_is12Hour(trimmed)) return _parse12Hour(trimmed, now);
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Returns the next occurrence of [timeStr] relative to [now].
  ///
  /// If the time has already passed today, rolls forward to tomorrow.
  /// Exact match with [now] is kept as today — not rolled forward.
  /// Returns null if [timeStr] cannot be parsed.
  static DateTime? nextOccurrence(String timeStr, DateTime now) {
    final candidate = parseTimeString(timeStr, now);
    if (candidate == null) return null;
    return candidate.isBefore(now)
        ? candidate.add(const Duration(days: 1))
        : candidate;
  }

  /// Builds a deterministic slot ID from [medicationId] and [scheduledTime].
  ///
  /// Format: "{medicationId}_{yyyy-MM-dd}_{HH:mm}"
  /// Same input always produces the same output — used to match
  /// a scheduled slot to its DoseLog without fragile time comparison.
  static String buildSlotId(String medicationId, DateTime scheduledTime) {
    final date =
        '${scheduledTime.year}-${scheduledTime.month.toString().padLeft(2, '0')}-${scheduledTime.day.toString().padLeft(2, '0')}';
    final time =
        '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}';
    return '${medicationId}_${date}_$time';
  }

  static String buildScheduleLabel(String timeStr, String frequency) {
    return '$timeStr · $frequency';
  }

  // --- private helpers ---

  static bool _is24Hour(String s) => RegExp(r'^\d{1,2}:\d{2}$').hasMatch(s);

  static bool _is12Hour(String s) =>
      RegExp(r'^\d{1,2}:\d{2}\s?(AM|PM)$', caseSensitive: false).hasMatch(s);

  static DateTime _parse24Hour(String timeStr, DateTime now) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  static DateTime _parse12Hour(String timeStr, DateTime now) {
    final upper = timeStr.toUpperCase().replaceAll(' ', '');
    final isPm = upper.endsWith('PM');
    final timePart = upper.replaceAll('AM', '').replaceAll('PM', '');
    final parts = timePart.split(':');
    var hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    if (isPm && hour != 12) hour += 12;
    if (!isPm && hour == 12) hour = 0;
    return DateTime(now.year, now.month, now.day, hour, minute);
  }
}
