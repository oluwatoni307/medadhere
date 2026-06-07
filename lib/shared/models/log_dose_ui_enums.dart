// ============================================
// FILE: log_dose_ui_enums.dart
// PATH: lib/features/log_dose/models/log_dose_ui_enums.dart
// LAYER: model
// DOMAIN: features/log_dose
// RESPONSIBLE FOR: UI-layer enums for the Log Dose screen.
//                  LogDoseScreenState is derived in-screen from DoseLogState fields.
//                  LogDoseChoice is a UI alias for DoseStatus — never leaks domain
//                  model into widget layer.
// MUST NEVER: Import Flutter, Riverpod, or any service/repository.
// → FLAG FOR SENIOR DEV: Confirm LogDoseScreenState and LogDoseChoice do not
//   already exist under different names elsewhere. If they do, delete this file
//   and update imports accordingly.
// ============================================

enum LogDoseScreenState {
  ready,
  writeInProgress,
  confirmed,
  undoAvailable,
  error,
}

enum LogDoseChoice { taken, skipped, missed }
