import '../../../products/domain/entities/catalog_filter.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/value_objects/catalog_filter_key.dart';
import '../../domain/value_objects/catalog_view_mode.dart';

sealed class CatalogFilterEvent {
  const CatalogFilterEvent();
}

/// Starts (or restarts, e.g. after switching the active organization/company)
/// the filterable catalog browsing screen (TASK-082).
///
/// When [initialViewMode]/[initialFilter] are provided (a Flutter Web deep
/// link/shared URL, or the caller entering a specific collection), they win
/// over any locally persisted preference — a shared link must always show
/// what it promised, never a stale local preference. When both are `null`,
/// the bloc restores the last saved `CatalogPreferences` for this
/// (organization, user), falling back to `CatalogViewMode.grid` +
/// `CatalogFilter.empty` when there is none yet.
final class CatalogFilterStarted extends CatalogFilterEvent {
  const CatalogFilterStarted({
    required this.organizationId,
    this.companyId,
    this.initialViewMode,
    this.initialFilter,
  });

  final String organizationId;
  final String? companyId;
  final CatalogViewMode? initialViewMode;
  final CatalogFilter? initialFilter;
}

/// Switches the active view mode, keeping the active [CatalogFilter]
/// unchanged (the specification's "troca de modo de visualização mantendo
/// filtro ativo"). Only meaningful for
/// `CatalogViewMode.isBrowsedByFilterBloc` modes — `favorites`/`lookbook`
/// are navigation shortcuts the host page intercepts before ever reaching
/// this bloc (see `CatalogViewMode`'s doc), and `bestSellers`/`recommended`
/// surface `CatalogFilterLoadStatus.unavailable` instead of fetching
/// anything.
final class CatalogFilterViewModeChanged extends CatalogFilterEvent {
  const CatalogFilterViewModeChanged(this.viewMode);

  final CatalogViewMode viewMode;
}

/// Replaces the active filter entirely (the filter panel's "Aplicar"
/// action) and reloads the first page.
final class CatalogFilterApplied extends CatalogFilterEvent {
  const CatalogFilterApplied(this.filter);

  final CatalogFilter filter;
}

/// Removes a single active filter chip — for a set-valued dimension
/// ([CatalogFilterKey.color]/[size]/[tag]), [value] identifies exactly
/// which one; every other dimension ignores [value].
final class CatalogFilterChipRemoved extends CatalogFilterEvent {
  const CatalogFilterChipRemoved(this.key, {this.value});

  final CatalogFilterKey key;
  final String? value;
}

/// Requests the next page, appending to (never replacing) the products
/// already shown — same "carregar mais" contract `ProductGridBloc` already
/// has.
final class CatalogFilterNextPageRequested extends CatalogFilterEvent {
  const CatalogFilterNextPageRequested();
}

/// Reloads the first page from scratch after a failed load.
final class CatalogFilterRetried extends CatalogFilterEvent {
  const CatalogFilterRetried();
}

/// The viewer tapped a card to open its product detail — logs
/// `product_viewed`. Navigation itself is decided by whoever hosts the
/// catalog filter screen, never by the bloc (same contract
/// `ProductGridBloc`/`FavoritesBloc` already set).
final class CatalogFilterProductOpened extends CatalogFilterEvent {
  const CatalogFilterProductOpened(this.product);

  final Product product;
}
