// ============================================
// FILE: battery_optimisation_service.dart
// PATH: lib/shared/services/battery_optimisation_service.dart
// LAYER: service
// DOMAIN: shared
// RESPONSIBLE FOR: Checks battery optimisation and autostart status on first
//                  launch only and prompts the user to enable both if needed.
// RECEIVES: Nothing
// RETURNS: Future<void>
// CONNECTS TO: main.dart (called once after auth resolves)
// MUST NEVER: Contain Riverpod, UI imports, or business logic
// ============================================

import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BatteryOptimisationService {
  BatteryOptimisationService._();

  static final BatteryOptimisationService instance =
      BatteryOptimisationService._();

  static const _batteryPromptKey = 'battery_prompt_shown';
  static const _autostartPromptKey = 'autostart_prompt_shown';

  // ─── public methods ───────────────────────────────────────

  /// Prompts for battery optimisation and autostart on every launch until
  /// each is confirmed enabled. Once confirmed, that prompt is permanently
  /// suppressed.
  Future<void> promptIfNeeded() async {
    await _promptBatteryOptimisation();
    await _promptAutoStart();
  }

  // ─── private helpers ──────────────────────────────────────

  Future<void> _promptBatteryOptimisation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadyShown = prefs.getBool(_batteryPromptKey) ?? false;
      if (alreadyShown) return;

      final isDisabled =
          await DisableBatteryOptimization.isBatteryOptimizationDisabled;
      if (isDisabled ?? true) {
        // Already disabled — mark as shown so we never check again
        await prefs.setBool(_batteryPromptKey, true);
        return;
      }

      await DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
      await prefs.setBool(_batteryPromptKey, true);
    } catch (e) {
      debugPrint('BatteryOptimisationService: battery prompt failed: $e');
    }
  }

  Future<void> _promptAutoStart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadyShown = prefs.getBool(_autostartPromptKey) ?? false;
      if (alreadyShown) return;

      final isEnabled = await DisableBatteryOptimization.isAutoStartEnabled;
      debugPrint('BatteryOptimisationService: isAutoStartEnabled = $isEnabled');

      if (isEnabled == true) {
        // Confirmed enabled — never ask again
        await prefs.setBool(_autostartPromptKey, true);
        return;
      }

      // null (Transsion/unknown OEM) or false — show the prompt
      await DisableBatteryOptimization.showEnableAutoStartSettings(
        'Enable Auto Start',
        'To ensure medication reminders are delivered after a device restart, '
            'please enable Auto Start for MedAdhere.',
      );
      // Do NOT mark as shown — re-prompt on every launch until confirmed
    } catch (e) {
      debugPrint('BatteryOptimisationService: autostart prompt failed: $e');
    }
  }
}
