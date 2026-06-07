// ============================================
// FILE: notification_service.dart
// PATH: lib/shared/services/notification_service.dart
// LAYER: service
// DOMAIN: shared
// RESPONSIBLE FOR: Wraps flutter_local_notifications — initialises plugin, requests permission,
//                  requests exact alarm permission, schedules and cancels notifications.
// RECEIVES: Notification id, title, body, payload, hour, minute
// RETURNS: void / bool
// CONNECTS TO: main.dart (init called once before runApp)
// MUST NEVER: Contain Riverpod, UI imports, or business logic
// ============================================

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _permissionGranted = false;
  bool _initialised = false;

  bool get permissionGranted => _permissionGranted;

  // ─── init ─────────────────────────────────────────────────

  Future<void> init({
    DidReceiveNotificationResponseCallback? onNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onBackgroundNotificationResponse,
  }) async {
    if (_initialised) return;

    // 1. Initialise timezone database and set local timezone
    tz_data.initializeTimeZones();
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

    // 2. Android-only init settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    // 3. Initialise plugin with notification response callbacks
    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse:
          onNotificationResponse ?? _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          onBackgroundNotificationResponse,
    );

    // 4. Create the notification channel explicitly — must exist before
    //    any zonedSchedule call or the alarm is silently dropped on Android 8+
    await _createNotificationChannel();

    // 5. Request notification permission (Android 13+)
    _permissionGranted = await _requestPermission();

    // 6. Request exact alarm permission (Android 12+)
    await _requestExactAlarmPermission();

    _initialised = true;
    debugPrint(
      'NotificationService: init complete, permission=$_permissionGranted',
    );
  }

  // ─── public methods ───────────────────────────────────────

  /// Schedules a daily recurring notification at [hour]:[minute].
  /// Silent no-op if permission was denied.
  Future<void> scheduleOne({
    required int id,
    required String title,
    required String body,
    required String payload,
    required int hour,
    required int minute,
  }) async {
    if (!_permissionGranted) {
      debugPrint('NotificationService: scheduleOne skipped — no permission');
      return;
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'medadhere_daily',
        'Daily Medication Reminders',
        channelDescription: 'Reminds you to take your medications on time',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: _nextInstanceOfTime(hour, minute),
        notificationDetails: details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint(
        'NotificationService: scheduled id=$id at $hour:${minute.toString().padLeft(2, '0')}',
      );
    } catch (e, stack) {
      debugPrint('NotificationService: zonedSchedule failed id=$id — $e');
      debugPrint(stack.toString());
    }
  }

  /// Cancels a single notification by [id].
  Future<void> cancelOne(int id) async => _plugin.cancel(id: id);

  /// Cancels all scheduled notifications.
  Future<void> cancelAll() async => _plugin.cancelAll();

  // ─── private helpers ──────────────────────────────────────

  /// Creates the Android notification channel that all medication reminders
  /// post to. Must be called during init() before any scheduling attempt.
  Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'medadhere_daily',
      'Daily Medication Reminders',
      description: 'Reminds you to take your medications on time',
      importance: Importance.high,
    );

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await android?.createNotificationChannel(channel);
    debugPrint('NotificationService: channel created');
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<bool> _requestPermission() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? false;
    } catch (e) {
      debugPrint('NotificationService: permission request failed: $e');
      return false;
    }
  }

  Future<void> _requestExactAlarmPermission() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android == null) return;
      final canSchedule = await android.canScheduleExactNotifications();
      if (canSchedule != true) {
        await android.requestExactAlarmsPermission();
      }
    } catch (e) {
      debugPrint(
        'NotificationService: exact alarm permission request failed: $e',
      );
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    debugPrint(
      'NotificationService: tapped id=${response.id} payload=${response.payload}',
    );
  }
}
