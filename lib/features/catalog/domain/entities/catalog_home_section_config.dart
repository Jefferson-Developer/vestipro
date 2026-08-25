import 'package:freezed_annotation/freezed_annotation.dart';

import 'catalog_home_section_type.dart';

part 'catalog_home_section_config.freezed.dart';

/// Data-driven configuration of one catalog home section (TASK-076): which
/// [type] to show, its [title]/[order]/[priority] and whether it is
/// [enabled] — sourced from `CatalogHomeConfigRepository` (Remote Config
/// today), never hardcoded in `CatalogHomePage`, so a manager can reorder,
/// rename, disable or re-prioritize a section without an app deploy.
@freezed
abstract class CatalogHomeSectionConfig with _$CatalogHomeSectionConfig {
  const factory CatalogHomeSectionConfig({
    required CatalogHomeSectionType type,
    required String title,
    required int order,
    required int priority,
    @Default(true) bool enabled,
    @Default(12) int itemLimit,
  }) = _CatalogHomeSectionConfig;
}

/// The safe, code-defined default composition (TASK-076) — applied whenever
/// Remote Config has not (yet) produced a valid override, mirroring
/// `configureRemoteConfig`'s "fetch never blocks, always falls back to a
/// local default" contract. Keeps the home within the "no máximo 4–6 seções
/// simultâneas" business rule (3 configured today; see
/// `CatalogHomeSectionType` for the 3 reserved-but-unimplemented types).
const List<CatalogHomeSectionConfig> defaultCatalogHomeSectionConfigs =
    <CatalogHomeSectionConfig>[
      CatalogHomeSectionConfig(
        type: CatalogHomeSectionType.featuredCollections,
        title: 'Coleções em destaque',
        order: 0,
        priority: 0,
        itemLimit: 8,
      ),
      CatalogHomeSectionConfig(
        type: CatalogHomeSectionType.newArrivals,
        title: 'Lançamentos',
        order: 1,
        priority: 1,
        itemLimit: 12,
      ),
      CatalogHomeSectionConfig(
        type: CatalogHomeSectionType.campaigns,
        title: 'Campanhas em destaque',
        order: 2,
        priority: 2,
        itemLimit: 6,
      ),
    ];
