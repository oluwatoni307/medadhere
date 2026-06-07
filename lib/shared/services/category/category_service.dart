// ============================================
// FILE: category_service.dart
// LAYER: service
// DOMAIN: medications
// RESPONSIBLE FOR: All category business logic — fetch, add, delete.
// RECEIVES: Auth UID (String), Category objects and IDs
// RETURNS: Future<List<Category>>, Future<void>
// CONNECTS TO: category_repository.dart, app_exception.dart
// MUST NEVER: Call Firestore directly or contain UI code
// ============================================

// internal — models
// Note: adjust path to match your project structure if needed
import '../../../core/errors/app_exception.dart';
import '../../models/category.dart';
import '../../repositories/category_repository.dart';

class CategoryService {
  const CategoryService(this._repository);

  final CategoryRepository _repository;

  Future<List<Category>> getCategories(String uid) async {
    try {
      return await _repository.getAll(uid);
    } catch (e) {
      throw AppException('Failed to load categories: $e');
    }
  }

  Future<void> addCategory(String uid, Category category) async {
    try {
      await _repository.add(uid, category);
    } catch (e) {
      throw AppException('Failed to add category: $e');
    }
  }

  Future<void> deleteCategory(String uid, String id) async {
    try {
      await _repository.delete(uid, id);
    } catch (e) {
      throw AppException('Failed to delete category: $e');
    }
  }
}
