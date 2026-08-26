/// Every catalog browsing mode from the specification (TASK-082, seção 10 de
/// `tasks.md`): grid, lista, novidades, mais vendidos, recomendados, pronta
/// entrega, catálogo por coleção/campanha, favoritos e lookbook.
///
/// Not every mode is fetched the same way — see [isBrowsedByFilterBloc] and
/// [requiresServerAggregation].
enum CatalogViewMode {
  grid,
  list,
  lookbook,
  byCollection,
  byCampaign,
  favorites,
  newArrivals,
  bestSellers,
  recommended,
  readyStock;

  /// Whether `CatalogFilterBloc` fetches this mode's products itself,
  /// through the same paginated `ListCatalogProductsUseCase` query every
  /// other browsable mode reuses.
  ///
  /// `false` for three different reasons, never conflated:
  /// - [lookbook]/[favorites] already have their own fully-built, tested
  ///   screen (`LookbookPage`/TASK-080, `FavoritesPage`/TASK-079) — routing
  ///   there instead avoids duplicating `LookbookBloc`/`FavoritesBloc`
  ///   (forbidden by this project's "não duplicar" rule).
  /// - [bestSellers]/[recommended] have no real data source at all yet
  ///   (no sales/order aggregation, no recommendation engine) — see
  ///   [requiresServerAggregation].
  /// - [byCampaign] is modeled here for completeness (it is one of the
  ///   view modes the specification lists), but this task wires no
  ///   campaign-scoped fetch path for it: `CatalogFilter` has no
  ///   `campaignId` dimension, and no caller in this task's delivered
  ///   screens ever selects it (`CatalogViewModeSelector` deliberately
  ///   excludes it — see its own doc). Campaign-scoped browsing continues
  ///   through the existing `LookbookPage`/`CampaignsPage` (TASK-080)
  ///   until a future task adds a real "produtos da campanha" grid.
  ///   [byCollection], by contrast, *is* fully wired — it is simply
  ///   `CatalogFilter.collectionId`, the same dimension the filter panel
  ///   already exposes.
  bool get isBrowsedByFilterBloc => switch (this) {
    CatalogViewMode.grid ||
    CatalogViewMode.list ||
    CatalogViewMode.byCollection ||
    CatalogViewMode.newArrivals ||
    CatalogViewMode.readyStock => true,
    CatalogViewMode.lookbook ||
    CatalogViewMode.favorites ||
    CatalogViewMode.byCampaign ||
    CatalogViewMode.bestSellers ||
    CatalogViewMode.recommended => false,
  };

  /// Whether this mode depends on server-side aggregated data (sales
  /// ranking / a recommendation engine) that does not exist in VestiPro yet
  /// — TASK-082's own business rules forbid ever inferring this client-side,
  /// so `CatalogFilterBloc` surfaces an explicit "unavailable" status for
  /// these instead of a fabricated ranking.
  bool get requiresServerAggregation => switch (this) {
    CatalogViewMode.bestSellers || CatalogViewMode.recommended => true,
    _ => false,
  };

  /// Whether this mode renders as a single-column list row instead of the
  /// default multi-column grid card — purely a layout concern, the
  /// underlying product query is identical to [CatalogViewMode.grid].
  bool get isListLayout => this == CatalogViewMode.list;

  static const _codeByMode = <CatalogViewMode, String>{
    CatalogViewMode.grid: 'grid',
    CatalogViewMode.list: 'list',
    CatalogViewMode.lookbook: 'lookbook',
    CatalogViewMode.byCollection: 'collection',
    CatalogViewMode.byCampaign: 'campaign',
    CatalogViewMode.favorites: 'favorites',
    CatalogViewMode.newArrivals: 'new',
    CatalogViewMode.bestSellers: 'bestsellers',
    CatalogViewMode.recommended: 'recommended',
    CatalogViewMode.readyStock: 'readystock',
  };

  /// Stable, URL/preferences-safe identifier — never the Dart enum [name]
  /// directly, so renaming an enum value in code never silently breaks an
  /// already-shared/bookmarked link or an already-persisted preference.
  String get code => _codeByMode[this]!;

  static CatalogViewMode fromCode(String? code) {
    for (final entry in _codeByMode.entries) {
      if (entry.value == code) return entry.key;
    }
    return CatalogViewMode.grid;
  }
}
