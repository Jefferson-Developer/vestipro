import 'package:freezed_annotation/freezed_annotation.dart';

import 'catalog_home_section.dart';

part 'catalog_home_snapshot.freezed.dart';

/// The last successfully-loaded catalog home, persisted by
/// `CatalogHomeCacheRepository` for stale-while-revalidate instant paint and
/// offline use (TASK-076). [savedAt] lets `CatalogHomeBloc`/`CatalogHomePage`
/// tell the viewer the data may be outdated instead of silently passing
/// cached data off as fresh.
@freezed
abstract class CatalogHomeSnapshot with _$CatalogHomeSnapshot {
  const factory CatalogHomeSnapshot({
    required List<CatalogHomeSection> sections,
    required DateTime savedAt,
  }) = _CatalogHomeSnapshot;
}
