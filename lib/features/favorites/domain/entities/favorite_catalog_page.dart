import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/variant_availability.dart';

/// Result of [ListFavoriteProductsUseCase]: the favorited `Product`s already
/// hydrated (TASK-079) — everything `FavoritesBloc`/`FavoritesPage` needs to
/// render the same `AppProductGrid` the catalog grid (TASK-077) uses,
/// without knowing anything about `FavoriteProduct`/Drift/Firestore itself.
///
/// [products] preserves the favorited order (most recently favorited
/// first) and silently drops any favorited id that no longer resolves to an
/// existing Product — [unavailableCount] is how many were dropped, so the
/// screen can surface that explicitly instead of a card that would
/// otherwise break (per TASK-079's "produto removido/descontinuado... nunca
/// card quebrado" rule).
final class FavoriteCatalogPage {
  const FavoriteCatalogPage({
    required this.products,
    required this.availabilityByProductId,
    required this.hasMore,
    required this.nextOffset,
    required this.unavailableCount,
  });

  final List<Product> products;
  final Map<String, VariantAvailability> availabilityByProductId;
  final bool hasMore;
  final int nextOffset;
  final int unavailableCount;
}
