import '../../../../core/errors/errors.dart';
import '../../domain/entities/category.dart';

enum CategoryListLoadStatus { loading, ready, failure }

enum CategoryListDeleteStatus { idle, deleting, success, failure }

enum CategoryListReorderStatus { idle, reordering, success, failure }

final class CategoryListState {
  const CategoryListState({
    this.loadStatus = CategoryListLoadStatus.loading,
    this.deleteStatus = CategoryListDeleteStatus.idle,
    this.reorderStatus = CategoryListReorderStatus.idle,
    this.organizationId = '',
    this.userId = '',
    this.categories = const <Category>[],
    this.searchQuery = '',
    this.loadFailure,
    this.deleteFailure,
    this.reorderFailure,
  });

  final CategoryListLoadStatus loadStatus;
  final CategoryListDeleteStatus deleteStatus;
  final CategoryListReorderStatus reorderStatus;
  final String organizationId;
  final String userId;
  final List<Category> categories;
  final String searchQuery;
  final Failure? loadFailure;
  final Failure? deleteFailure;
  final Failure? reorderFailure;

  /// Root categories (`parentId == null`), already in manual sort order.
  List<Category> get rootCategories => childrenOf(null);

  /// Direct children of [parentId], already in manual sort order.
  List<Category> childrenOf(String? parentId) {
    final children =
        categories
            .where((category) => category.parentId == parentId)
            .toList(growable: false)
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return children;
  }

  /// Whether any category of the tree matches [searchQuery].
  bool get isSearching => searchQuery.trim().isNotEmpty;

  /// Flat search results (any level), used instead of the nested tree while
  /// [isSearching] is true.
  List<Category> get searchResults {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return const <Category>[];
    return categories
        .where((category) => category.name.toLowerCase().contains(query))
        .toList(growable: false)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Category? categoryById(String id) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  CategoryListState copyWith({
    CategoryListLoadStatus? loadStatus,
    CategoryListDeleteStatus? deleteStatus,
    CategoryListReorderStatus? reorderStatus,
    String? organizationId,
    String? userId,
    List<Category>? categories,
    String? searchQuery,
    Failure? loadFailure,
    Failure? deleteFailure,
    Failure? reorderFailure,
    bool clearLoadFailure = false,
    bool clearDeleteFailure = false,
    bool clearReorderFailure = false,
  }) {
    return CategoryListState(
      loadStatus: loadStatus ?? this.loadStatus,
      deleteStatus: deleteStatus ?? this.deleteStatus,
      reorderStatus: reorderStatus ?? this.reorderStatus,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      categories: categories ?? this.categories,
      searchQuery: searchQuery ?? this.searchQuery,
      loadFailure: clearLoadFailure ? null : loadFailure ?? this.loadFailure,
      deleteFailure: clearDeleteFailure
          ? null
          : deleteFailure ?? this.deleteFailure,
      reorderFailure: clearReorderFailure
          ? null
          : reorderFailure ?? this.reorderFailure,
    );
  }
}
