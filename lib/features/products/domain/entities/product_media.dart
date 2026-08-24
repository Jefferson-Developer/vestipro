import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/product_media_type.dart';

part 'product_media.freezed.dart';

/// A single photo or video attached to a [Product] (TASK-068), replacing the
/// plain `photoUrls`/`videoUrls` string lists TASK-064 first modeled: those
/// could not represent display order, which photo is the product's cover, or
/// a photo taken specifically for one color (TASK-070).
///
/// [id] doubles as the Storage file name for this media (see
/// `StoragePaths.productFile`), so a caller can always rebuild the exact
/// upload path from `organizationId`/`productId`/[id] alone — no separate
/// "storage path" field needs to be persisted or kept in sync with [url].
///
/// [thumbnailUrl] is the smaller, catalog-grid-safe rendition generated at
/// upload time (TASK-068's "nunca carregar a imagem original em telas de
/// grid" rule) — `null` only for a [ProductMediaType.video], which has no
/// client-generated thumbnail yet (see this task's completion notes).
///
/// [order] is scoped within [type]: photos and videos are reordered as two
/// independent sequences, never as one interleaved list.
///
/// [principal] marks the single photo used as the product's cover across
/// catalog grids/cards; always `false` for a video. Exactly zero or one
/// photo in a given `Product.media` may have `principal == true` — enforced
/// by `product_media_rules.dart`, never left to a widget to keep consistent.
///
/// [colorId] is optional and, when set, scopes this media to one specific
/// `ProductColor` (TASK-070, not yet implemented) instead of the product as
/// a whole.
@freezed
abstract class ProductMedia with _$ProductMedia {
  const factory ProductMedia({
    required String id,
    required ProductMediaType type,
    required String url,
    String? thumbnailUrl,
    required int order,
    @Default(false) bool principal,
    String? colorId,
  }) = _ProductMedia;
}
