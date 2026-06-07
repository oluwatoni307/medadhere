//============================================
//FILE: category_service_provider.dart
//LAYER: service
//DOMAIN: medications
//RESPONSIBLE FOR: Riverpod provider exposing CategoryService for injection.
//RECEIVES: Nothing
//RETURNS: CategoryService instance
//CONNECTS TO: category_repository.dart, category_service.dart
//MUST NEVER: Contain UI code or business logic
//============================================

// packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// internal — repositories
import '../../repositories/category_repository.dart';

// internal — services
import 'category_service.dart';

part 'category_service_provider.g.dart';

@riverpod
CategoryService categoryService(Ref ref) {
  return CategoryService(CategoryRepository(FirebaseFirestore.instance));
}
