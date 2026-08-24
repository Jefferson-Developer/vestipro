import 'entities/category.dart';

/// Guards the `Category` tree (TASK-067) against becoming a cycle: a
/// category can never end up as its own ancestor. Kept as a pure function,
/// independent from `CategoryRepository`, so `CreateCategoryUseCase`/
/// `UpdateCategoryUseCase` can validate a proposed move before persisting
/// it, and so it can be unit-tested without a fake repository.
final class CategoryCycleValidator {
  const CategoryCycleValidator._();

  /// Whether moving [categoryId] under [newParentId] would create a cycle:
  /// either [newParentId] is [categoryId] itself, or [newParentId] is a
  /// descendant of [categoryId] (making [categoryId] an ancestor of its own
  /// new parent). Moving to the root ([newParentId] `null`) never cycles.
  static bool wouldCreateCycle({
    required List<Category> categories,
    required String categoryId,
    required String? newParentId,
  }) {
    if (newParentId == null) return false;
    if (newParentId == categoryId) return true;

    final parentById = <String, String?>{
      for (final category in categories) category.id: category.parentId,
    };

    final visited = <String>{};
    String? current = newParentId;
    while (current != null) {
      if (current == categoryId) return true;
      if (!visited.add(current)) {
        // Defensively stop on a pre-existing cycle in the stored data
        // instead of looping forever.
        return true;
      }
      current = parentById[current];
    }
    return false;
  }
}
