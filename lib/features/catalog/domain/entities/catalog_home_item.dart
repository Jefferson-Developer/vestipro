import 'package:freezed_annotation/freezed_annotation.dart';

part 'catalog_home_item.freezed.dart';

/// One tappable tile inside a [CatalogHomeSection] (TASK-076) — already
/// flattened to exactly what the Design System's product card/carousel
/// needs to render (see `AppProductCarousel`), regardless of whether the
/// underlying domain object is a `Product`, a `Collection` or a
/// `CatalogCampaign`.
///
/// This flat shape is also what `CatalogHomeCacheRepository` persists for
/// stale-while-revalidate: caching the same shape the UI already renders
/// means the cached and the freshly-loaded home go through the exact same
/// widget code, with no separate "cached view" to keep in sync.
///
/// [id] is the id of the underlying `Product`/`Collection`/`CatalogCampaign`
/// — the caller combines it with the parent section's
/// `CatalogHomeSectionType` (via `CatalogHomeSectionOpened`/an
/// `onSectionItemTap` callback) to know what to open next.
@freezed
abstract class CatalogHomeItem with _$CatalogHomeItem {
  const factory CatalogHomeItem({
    required String id,
    required String title,
    String? subtitle,
    String? imageUrl,
    String? badgeLabel,
  }) = _CatalogHomeItem;
}
