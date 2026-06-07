import 'package:shared_preferences/shared_preferences.dart';

// PATH: lib/shared/services/onboarding_preference_service.dart
// DOMAIN: shared
// LAYER: service
// RESPONSIBLE FOR: Wraps SharedPreferencesAsync to read and write onboarding intro seen and name collected completion flags

class OnboardingPreferenceService {
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  static const String _keyIntroSeen = 'intro_seen';
  static const String _keyNameCollected = 'name_collected';

  Future<bool> isIntroSeen() async {
    final bool? value = await _prefs.getBool(_keyIntroSeen);
    return value ?? false;
  }

  Future<void> markIntroSeen() async {
    await _prefs.setBool(_keyIntroSeen, true);
  }

  Future<bool> isNameCollected() async {
    final bool? value = await _prefs.getBool(_keyNameCollected);
    return value ?? false;
  }

  Future<void> markNameCollected() async {
    await _prefs.setBool(_keyNameCollected, true);
  }
}
