import 'favorite_product.dart';

/// One offset-paginated page of [FavoriteRepository.listFavorites]
/// (TASK-079) — newest-favorited first.
///
/// Pagination is offset-based (not cursor-based like
/// `ProductCatalogPage`/`ListCatalogProductsUseCase`) because the local
/// source of truth is a small, per-user Drift table, not an
/// unbounded/shared collection: an occasional skip/duplicate under
/// concurrent favoriting while paging is an acceptable trade-off for the
/// simpler query, unlike the full catalog grid.
final class FavoriteProductPage {
  const FavoriteProductPage({required this.items, required this.hasMore});

  final List<FavoriteProduct> items;
  final bool hasMore;
}
