// ============================================
// FILE: hive_init_service.dart
// PATH: lib/shared/services/hive_init_service.dart
// LAYER: service
// DOMAIN: shared
// RESPONSIBLE FOR: Initialises Hive, registers all adapters, opens all three domain boxes.
// RECEIVES: Nothing
// RETURNS: Future<void>
// CONNECTS TO: main.dart (called once before runApp)
// MUST NEVER: Contain Riverpod, UI imports, or business logic
// ============================================

import 'package:hive_flutter/hive_flutter.dart';

import '../models/category.dart';
import '../models/dose_log.dart';
import '../models/medication.dart';

class HiveInitService {
  HiveInitService._(); // prevent instantiation

  static const String medicationsBox = 'medications_box';
  static const String doseLogsBox = 'dose_logs_box';
  static const String categoriesBox = 'categories_box';

  static Future<void> init() async {
    // 1. Initialise Hive with Flutter path resolution
    await Hive.initFlutter();

    // 2. Register adapters — order matters:
    //    DoseStatusAdapter before DoseLogAdapter (dependency)
    Hive.registerAdapter(CategoryAdapter()); // typeId: 2
    Hive.registerAdapter(DoseStatusAdapter()); // typeId: 3
    Hive.registerAdapter(DoseLogAdapter()); // typeId: 4
    Hive.registerAdapter(MedicationAdapter()); // typeId: 1

    // 3. Open boxes
    await Hive.openBox<Category>(categoriesBox);
    await Hive.openBox<Medication>(medicationsBox);
    await Hive.openBox<DoseLog>(doseLogsBox);
  }
}
