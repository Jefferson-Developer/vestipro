import '../../domain/entities/favorite_product.dart';

/// Best-effort background mirror of the local favorite store to Firestore
/// (TASK-079) — never the source of truth (Drift is), and never on the path
/// of the favorite button's own optimistic UI: `DriftFavoriteRepository`
/// calls this after the local write already succeeded/returned, so a slow
/// or failed remote call never blocks or breaks favoriting/unfavoriting.
abstract interface class FavoriteRemoteDataSource {
  Future<void> upsert(FavoriteProduct favorite);

  Future<void> delete({
    required String organizationId,
    required String userId,
    required String productId,
  });
}
