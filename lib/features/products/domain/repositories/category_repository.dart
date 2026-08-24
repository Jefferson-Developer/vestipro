import '../../../../core/utils/utils.dart';
import '../entities/category.dart';

/// Contract for reading and writing `Category` documents scoped under one
/// Organization (TASK-067): the single source of truth for the
/// category/subcategory tree reused by `ProductFormPage`'s category picker
/// and, later, by the catalog filters (EPIC-10).
abstract interface class CategoryRepository {
  Future<AppResult<Category>> create({required Category category});

  Future<AppResult<Category>> update({required Category category});

  /// Lists every non-deleted Category of [organizationId], every level of
  /// the tree at once. Never returns a Category belonging to a different
  /// organization.
  Future<AppResult<List<Category>>> listByOrganization(String organizationId);

  Future<AppResult<Category>> getById({
    required String organizationId,
    required String id,
  });

  /// Whether a non-deleted Category named [name] (case-insensitive,
  /// trimmed) already exists among the siblings of [parentId] (`null` means
  /// the root level) in [organizationId]. [excludingCategoryId] lets an
  /// update check for duplicates without flagging the Category being
  /// edited.
  Future<AppResult<bool>> existsByName({
    required String organizationId,
    required String name,
    String? parentId,
    String? excludingCategoryId,
  });

  /// Whether any non-deleted `Product` of [organizationId] still references
  /// [categoryId] as its `categoryId` or `subcategoryId`. Used to block
  /// deleting a Category still in use, the same guard
  /// `SeasonRepository.hasCollections` applies before deleting a Season.
  Future<AppResult<bool>> hasProducts({
    required String organizationId,
    required String categoryId,
  });

  Future<AppResult<Category>> delete({
    required String organizationId,
    required String id,
    required String deletedBy,
  });

  /// Persists a new manual sibling order: [orderedIds] must be exactly the
  /// set of non-deleted Categories whose `parentId` is [parentId] (`null`
  /// for the root level), reassigning `sortOrder` to match their position
  /// in the list. Never changes any Category's `parentId` — reparenting is
  /// only ever an explicit `UpdateCategoryUseCase` call, never a side effect
  /// of reordering siblings.
  Future<AppResult<List<Category>>> reorder({
    required String organizationId,
    required String? parentId,
    required List<String> orderedIds,
    required String updatedBy,
  });
}
