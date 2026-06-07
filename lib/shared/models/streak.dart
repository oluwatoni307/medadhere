// ============================================
// FILE: streak_display_state.dart
// LAYER: model
// DOMAIN: shared
// RESPONSIBLE FOR: Enum representing the three emotional states of the streak display surface
// MUST NEVER: contain logic — enum values only
// ============================================

enum StreakDisplayState {
  firstTime, // user has never taken a dose
  lapsed, // had a streak, broke it, now at zero
  active, // streak >= 1
}
