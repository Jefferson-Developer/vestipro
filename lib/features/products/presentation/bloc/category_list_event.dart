import '../../domain/entities/category.dart';

sealed class CategoryListEvent {
  const CategoryListEvent();
}

final class CategoryListStarted extends CategoryListEvent {
  const CategoryListStarted({
    required this.organizationId,
    required this.userId,
  });

  final String organizationId;
  final String userId;
}

final class CategoryListRefreshRequested extends CategoryListEvent {
  const CategoryListRefreshRequested();
}

final class CategoryListSearchChanged extends CategoryListEvent {
  const CategoryListSearchChanged(this.query);

  final String query;
}

final class CategoryListDeleteRequested extends CategoryListEvent {
  const CategoryListDeleteRequested(this.category);

  final Category category;
}

/// Persists a new manual order for every sibling of [parentId] (`null` for
/// the root level). [orderedIds] must already be the full sibling group in
/// its new order — never a partial list — so a Web drag-and-drop or a
/// mobile "mover para cima/baixo" action always reorders one complete
/// sibling group at a time, never reparenting anything by accident.
final class CategoryListReorderRequested extends CategoryListEvent {
  const CategoryListReorderRequested({
    required this.parentId,
    required this.orderedIds,
  });

  final String? parentId;
  final List<String> orderedIds;
}
