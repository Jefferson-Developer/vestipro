import '../../../products/domain/entities/catalog_filter.dart';
import '../value_objects/catalog_view_mode.dart';

/// The last catalog view mode/filter a signed-in user left the catalog
/// browsing screen with (TASK-082) — persisted per (organization, user) so
/// reopening the catalog restores exactly where they left off, and so the
/// same device never leaks one organization's filter preference into
/// another after switching the active organization.
final class CatalogPreferences {
  const CatalogPreferences({
    this.viewMode = CatalogViewMode.grid,
    this.filter = CatalogFilter.empty,
  });

  final CatalogViewMode viewMode;
  final CatalogFilter filter;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CatalogPreferences &&
        other.viewMode == viewMode &&
        other.filter == filter;
  }

  @override
  int get hashCode => Object.hash(viewMode, filter);
}
