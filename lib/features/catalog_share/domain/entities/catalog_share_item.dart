import 'package:freezed_annotation/freezed_annotation.dart';

part 'catalog_share_item.freezed.dart';

/// A lightweight, self-contained snapshot of one shared product — everything
/// `CatalogSharePublicPage` needs to render a card, with no further lookup
/// (TASK-081, EPIC-10).
///
/// Deliberately not a reference to `Product` (`lib/features/products`):
/// `CatalogShare` travels to an anonymous recipient with no session/
/// organization context at all, and the catalog's own product repository is
/// still local-first (`SharedPreferencesProductRepository`, see TASK-080's
/// "Decisões técnicas"), so there is no Firestore-side product store the
/// public page could resolve a live `Product` from. The snapshot is taken
/// client-side, from whatever `Product` the vendor already has in memory,
/// at the moment the share is created — it never changes afterwards even if
/// the underlying product does.
@freezed
abstract class CatalogShareItem with _$CatalogShareItem {
  const factory CatalogShareItem({
    required String productId,
    required String name,
    String? imageUrl,
  }) = _CatalogShareItem;
}
