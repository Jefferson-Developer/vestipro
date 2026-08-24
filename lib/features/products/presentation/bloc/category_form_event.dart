import '../../domain/entities/category.dart';

sealed class CategoryFormEvent {
  const CategoryFormEvent();
}

final class CategoryFormStarted extends CategoryFormEvent {
  const CategoryFormStarted({
    required this.organizationId,
    required this.userId,
    this.initialCategory,
    this.initialParentId,
  });

  final String organizationId;
  final String userId;

  /// The Category being edited, or `null` when creating one.
  final Category? initialCategory;

  /// Pre-selects the parent when creating a subcategory directly from a
  /// parent's row (e.g. "Adicionar subcategoria"). Ignored when
  /// [initialCategory] is set — editing always starts from the Category's
  /// own current parent.
  final String? initialParentId;
}

final class CategoryFormNameChanged extends CategoryFormEvent {
  const CategoryFormNameChanged(this.name);

  final String name;
}

final class CategoryFormParentSelected extends CategoryFormEvent {
  const CategoryFormParentSelected(this.parentId);

  final String? parentId;
}

final class CategoryFormSubmitted extends CategoryFormEvent {
  const CategoryFormSubmitted();
}
