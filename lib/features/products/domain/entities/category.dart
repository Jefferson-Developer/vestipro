import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';

/// Hierarchical catalog taxonomy entry (TASK-067): the single source of
/// truth for "categoria"/"subcategoria" used both by `ProductFormPage`'s
/// category picker (TASK-065) and, later, by the catalog filters (EPIC-10).
///
/// [parentId] is null for a root "categoria" and points at another
/// `Category` of the same [organizationId] for a "subcategoria". The model
/// only enforces two conceptual levels today (category > subcategory,
/// mirroring `Product.categoryId`/`Product.subcategoryId`), but nothing here
/// prevents a deeper chain in the future — [parentId] can point at any
/// ancestor depth. Cycle safety (a category can never become its own
/// descendant) is enforced by `CategoryCycleValidator`, never by this
/// entity.
///
/// [sortOrder] is the explicit manual order among siblings (categories that
/// share the same [parentId]), persisted by `ReorderCategoriesUseCase` —
/// never inferred from creation order or name.
///
/// Category belongs to exactly one [organizationId]; the tree is never
/// shared between tenants.
@freezed
abstract class Category with _$Category {
  const Category._();

  const factory Category({
    required String id,
    required String organizationId,
    required String name,
    String? parentId,
    required int sortOrder,
    required int version,
    required DateTime createdAt,
    required String createdBy,
    required DateTime updatedAt,
    required String updatedBy,
    DateTime? deletedAt,
  }) = _Category;

  bool get isRoot => parentId == null;
}
