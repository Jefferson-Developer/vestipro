import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/favorite_sync_status.dart';

part 'favorite_product.freezed.dart';

/// A product a representative saved for later consultation during a visit
/// or negotiation (TASK-079, EPIC-10).
///
/// Favorites are strictly personal — [userId] scopes every read/write, they
/// are never shared across a team — and tenant-scoped by [organizationId]
/// like every other entity in the app. [companyId] is carried along only to
/// mirror `Product.companyId` (some organizations share a single catalog
/// across companies), it plays no role in the favorite/unfavorite identity
/// itself, which is always the ([organizationId], [userId], [productId])
/// triple.
///
/// [syncStatus] tracks whether this local (Drift, source of truth) write has
/// already been mirrored to
/// `organizations/{organizationId}/favorites/{userId}_{productId}` — see
/// `DriftFavoriteRepository` for the local-first write + best-effort
/// background sync this entity flows through.
@freezed
abstract class FavoriteProduct with _$FavoriteProduct {
  const factory FavoriteProduct({
    required String productId,
    required String userId,
    required String organizationId,
    String? companyId,
    required DateTime createdAt,
    required FavoriteSyncStatus syncStatus,
  }) = _FavoriteProduct;
}
