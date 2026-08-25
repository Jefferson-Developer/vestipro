import '../../../../core/utils/utils.dart';
import '../entities/favorite_product.dart';
import '../entities/favorite_product_page.dart';

/// Domain contract for personal, per-user product favorites (TASK-079),
/// decoupled from Drift/Firestore.
///
/// The local store (Drift) is always the source of truth for reads and the
/// first write target — every method here must return/complete without
/// depending on connectivity, so favoriting/unfavoriting works exactly the
/// same online or offline. Mirroring a write to Firestore is this
/// repository's own responsibility in the background, never something a
/// caller (use case/BLoC) has to orchestrate itself.
abstract interface class FavoriteRepository {
  /// Reactive set of every favorited `Product.id` for
  /// ([organizationId], [userId]) — re-emits immediately after a local
  /// [addFavorite]/[removeFavorite] write, which is what gives the favorite
  /// button its optimistic, offline-proof feel.
  Stream<Set<String>> watchFavoriteProductIds({
    required String organizationId,
    required String userId,
  });

  /// Favorites [productId], or is a no-op returning the existing row if it
  /// is already favorited — repeated taps before a previous call's local
  /// write lands never create a duplicate favorite (TASK-079's idempotency
  /// requirement).
  Future<AppResult<FavoriteProduct>> addFavorite({
    required String organizationId,
    required String userId,
    required String productId,
    String? companyId,
  });

  /// Unfavorites [productId], or is a no-op if it was not favorited.
  Future<AppResult<void>> removeFavorite({
    required String organizationId,
    required String userId,
    required String productId,
  });

  /// Newest-favorited-first page of every currently favorited product id
  /// for ([organizationId], [userId]).
  Future<AppResult<FavoriteProductPage>> listFavorites({
    required String organizationId,
    required String userId,
    int offset = 0,
    int limit = 20,
  });
}
