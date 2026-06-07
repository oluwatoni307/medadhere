// ============================================
// FILE: main.dart
// PATH: lib/main.dart
// LAYER: utility
// DOMAIN: shared
// RESPONSIBLE FOR: Bootstraps top-level notification response handler before app render.
// MUST NEVER: Call HiveInitService from any layer other than this file
// ============================================
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'shared/services/battery_optimisation_service.dart';
import 'shared/services/hive_init_service.dart';
import 'shared/services/notification_service.dart';
import 'shared/models/notification_payload.dart';
import 'core/config/router.dart';

// Global container — single source of truth for both
// the widget tree and the top-level notification handler
final ProviderContainer globalContainer = ProviderContainer();

@pragma('vm:entry-point')
void onNotificationResponse(NotificationResponse response) {
  final rawPayload = response.payload;
  if (rawPayload == null || rawPayload.isEmpty) return;
  try {
    final payload = NotificationPayload.fromPayload(rawPayload);
    final router = globalContainer.read(routerProvider);
    router.go('/log-dose', extra: payload.toJson());
  } catch (e) {
    debugPrint('onNotificationResponse: failed to handle payload — $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await HiveInitService.init();
  } catch (e, stack) {
    debugPrint('Fatal: HiveInitService.init() failed: $e\n$stack');
    return;
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, stack) {
    debugPrint('Fatal: Firebase.initializeApp() failed: $e\n$stack');
    return;
  }
  // after Firebase.initializeApp()
  await BatteryOptimisationService.instance.promptIfNeeded();
  await NotificationService.instance.init(
    onNotificationResponse: onNotificationResponse,
    onBackgroundNotificationResponse: onNotificationResponse,
  );

  runApp(
    UncontrolledProviderScope(
      container: globalContainer, // widget tree uses the same container
      child: const App(),
    ),
  );
}
