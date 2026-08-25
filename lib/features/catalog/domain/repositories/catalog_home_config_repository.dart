import '../../../../core/utils/utils.dart';
import '../entities/catalog_home_section_config.dart';

/// Source of the catalog home's section composition (TASK-076): which
/// `CatalogHomeSectionType`s to show, in which order/priority, with which
/// title. Backed by Remote Config so a manager can reorder/rename/disable a
/// section without an app deploy (TASK-076 business rule) — never hardcoded
/// in `CatalogHomePage`.
abstract interface class CatalogHomeConfigRepository {
  /// Never fails in practice: an implementation must fall back to
  /// [defaultCatalogHomeSectionConfigs] whenever the remote source has no
  /// value yet or cannot be parsed, mirroring `configureRemoteConfig`'s
  /// "never blocks, always falls back to a safe local default" contract —
  /// still returns `AppResult` so a future non-Remote-Config-backed
  /// implementation (e.g. a Firestore config collection) can report a real
  /// I/O failure if it ever needs to.
  Future<AppResult<List<CatalogHomeSectionConfig>>> getSectionConfigs(
    String organizationId,
  );
}
