/// Filter/view state of the Inventory Dashboard (TASK-139, EPIC-17): which
/// company, which reference month, and which depósito/coleção/categoria
/// narrows the KPI cards and the "produtos parados" list — mirrored into the
/// route's query parameters so a Flutter Web reload/share link restores
/// exactly the same view, same contract `ProductDashboardFilters`/
/// `CustomerDashboardFilters` already set.
///
/// **`warehouseId` e `collectionId` nunca são combinados na leitura de
/// cobertura/sell-through/giro.** `StockTurnoverMetricSnapshot` (TASK-094)
/// só existe por um escopo independente por vez —
/// `StockTurnoverScopeType.product`/`.variant`/`.collection`/`.warehouse` —
/// nunca uma combinação produto+depósito ou coleção+depósito. Quando ambos
/// estão preenchidos, `LoadInventoryDashboardSnapshotUseCase` prioriza
/// [warehouseId] (a leitura mais operacional para um gestor de estoque) e
/// documenta essa prioridade — nunca fabrica uma leitura combinada que a
/// TASK-094 não sustenta.
///
/// Deliberately no `categoryId`-scoped coverage/turnover reading either:
/// `StockTurnoverScopeType` carries no `category` variant at all, apenas
/// `product`/`variant`/`collection`/`warehouse`. [categoryId] narrows apenas
/// a listagem de "produtos parados" (via `CatalogFilter.categoryId`, real e
/// suportado por `ProductRepository.listCatalog`), nunca as KPIs de
/// cobertura/giro — mesma "nunca fabricar um filtro que não filtra nada"
/// precedent `ProductDashboardFilters`'s own doc already sets.
final class InventoryDashboardFilters {
  const InventoryDashboardFilters({
    required this.companyId,
    required this.year,
    required this.month,
    this.warehouseId,
    this.collectionId,
    this.categoryId,
    this.stalledCoverageDaysThreshold = 60,
  }) : assert(month >= 1 && month <= 12, 'month must be between 1 and 12.');

  /// Builds the filters for the current calendar month (UTC) — the landing
  /// default every caller sees before touching a filter.
  factory InventoryDashboardFilters.currentMonth({
    required String companyId,
    DateTime? now,
  }) {
    final reference = (now ?? DateTime.now()).toUtc();
    return InventoryDashboardFilters(
      companyId: companyId,
      year: reference.year,
      month: reference.month,
    );
  }

  final String companyId;
  final int year;
  final int month;

  /// Narrows the KPI card's coverage/sell-through/giro scope to one
  /// `Warehouse` (TASK-089) and filters the consolidated alert list
  /// (`ListStockAlertsUseCase` already supports `warehouseId`, TASK-093).
  /// `null` means "todos os depósitos ativos" — the KPI card then folds
  /// (média ponderada) sobre todo depósito ativo da empresa, bounded pelo
  /// número de depósitos ativos (nunca uma leitura ilimitada).
  final String? warehouseId;

  /// Narrows the KPI card's coverage/sell-through/giro scope to one
  /// `Collection` (`StockTurnoverScopeType.collection`) and narrows a
  /// listagem de "produtos parados" ao catálogo dessa coleção
  /// (`CatalogFilter.collectionId`). `null` means "todas as coleções".
  final String? collectionId;

  /// Narrows apenas a listagem de "produtos parados"
  /// (`CatalogFilter.categoryId`) — ver este arquivo's own doc para a razão
  /// de não filtrar as KPIs de cobertura/giro por categoria.
  final String? categoryId;

  /// Piso de cobertura em dias (TASK-094's `stockCoverageDays`) acima do
  /// qual um produto é sinalizado como "parado" na listagem — o "período
  /// configurável" que o escopo técnico desta task pede. Ajustável pelo
  /// gestor (ex.: 30/60/90 dias); nunca o mesmo limiar
  /// organização/categoria-configurado que `HighStockLowTurnoverInsightRule`
  /// (TASK-128) usa internamente (esse limiar não é lido pelo client hoje —
  /// ver `LoadInventoryDashboardStalledProductsUseCase`'s own doc), apenas
  /// um piso equivalente e explícito na UI deste dashboard.
  final int stalledCoverageDaysThreshold;

  /// `YYYY-MM`, the exact `periodKey` grain other EPIC-17 dashboards use for
  /// their own calendar-month filter.
  String get monthKey => '$year-${month.toString().padLeft(2, '0')}';

  /// Inclusive start / exclusive end of [year]/[month], always UTC so every
  /// downstream turnover-period comparison is timezone-stable.
  DateTime get periodStart => DateTime.utc(year, month);

  DateTime get periodEnd => DateTime.utc(year, month + 1);

  /// The immediately preceding calendar month.
  InventoryDashboardFilters get previousMonth {
    final previous = DateTime.utc(year, month - 1);
    return copyWith(year: previous.year, month: previous.month);
  }

  /// Whether [year]/[month] is strictly after the month [now] falls in — the
  /// UI never lets the caller navigate the month picker into the future.
  bool isAfter(DateTime now) {
    final reference = now.toUtc();
    return year > reference.year ||
        (year == reference.year && month > reference.month);
  }

  InventoryDashboardFilters copyWith({
    String? companyId,
    int? year,
    int? month,
    String? warehouseId,
    bool clearWarehouseId = false,
    String? collectionId,
    bool clearCollectionId = false,
    String? categoryId,
    bool clearCategoryId = false,
    int? stalledCoverageDaysThreshold,
  }) {
    return InventoryDashboardFilters(
      companyId: companyId ?? this.companyId,
      year: year ?? this.year,
      month: month ?? this.month,
      warehouseId: clearWarehouseId ? null : (warehouseId ?? this.warehouseId),
      collectionId: clearCollectionId
          ? null
          : (collectionId ?? this.collectionId),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      stalledCoverageDaysThreshold:
          stalledCoverageDaysThreshold ?? this.stalledCoverageDaysThreshold,
    );
  }

  /// Serializes into query parameters for the route location, restoring the
  /// same company/month/depósito/coleção/categoria/limiar on a Flutter Web
  /// reload/share link.
  Map<String, String> toQueryParameters() {
    return <String, String>{
      'companyId': companyId,
      'month': monthKey,
      if (warehouseId != null && warehouseId!.trim().isNotEmpty)
        'warehouseId': warehouseId!,
      if (collectionId != null && collectionId!.trim().isNotEmpty)
        'collectionId': collectionId!,
      if (categoryId != null && categoryId!.trim().isNotEmpty)
        'categoryId': categoryId!,
      'stalledDays': stalledCoverageDaysThreshold.toString(),
    };
  }

  factory InventoryDashboardFilters.fromQueryParameters(
    Map<String, String> queryParameters, {
    required String defaultCompanyId,
    DateTime? now,
  }) {
    final companyId = queryParameters['companyId']?.trim();
    final warehouseId = queryParameters['warehouseId']?.trim();
    final collectionId = queryParameters['collectionId']?.trim();
    final categoryId = queryParameters['categoryId']?.trim();
    final monthRaw = queryParameters['month']?.trim();
    final parsedMonth = monthRaw != null && monthRaw.isNotEmpty
        ? RegExp(r'^(\d{4})-(\d{2})$').firstMatch(monthRaw)
        : null;
    final stalledDaysRaw = int.tryParse(
      queryParameters['stalledDays']?.trim() ?? '',
    );

    final resolvedCompanyId = (companyId == null || companyId.isEmpty)
        ? defaultCompanyId
        : companyId;
    final resolvedWarehouseId = (warehouseId == null || warehouseId.isEmpty)
        ? null
        : warehouseId;
    final resolvedCollectionId = (collectionId == null || collectionId.isEmpty)
        ? null
        : collectionId;
    final resolvedCategoryId = (categoryId == null || categoryId.isEmpty)
        ? null
        : categoryId;
    final resolvedStalledDays = (stalledDaysRaw == null || stalledDaysRaw < 1)
        ? 60
        : stalledDaysRaw;

    if (parsedMonth == null) {
      final current = InventoryDashboardFilters.currentMonth(
        companyId: resolvedCompanyId,
        now: now,
      );
      return current.copyWith(
        warehouseId: resolvedWarehouseId,
        collectionId: resolvedCollectionId,
        categoryId: resolvedCategoryId,
        stalledCoverageDaysThreshold: resolvedStalledDays,
      );
    }

    return InventoryDashboardFilters(
      companyId: resolvedCompanyId,
      year: int.parse(parsedMonth.group(1)!),
      month: int.parse(parsedMonth.group(2)!).clamp(1, 12),
      warehouseId: resolvedWarehouseId,
      collectionId: resolvedCollectionId,
      categoryId: resolvedCategoryId,
      stalledCoverageDaysThreshold: resolvedStalledDays,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is InventoryDashboardFilters &&
        companyId == other.companyId &&
        year == other.year &&
        month == other.month &&
        warehouseId == other.warehouseId &&
        collectionId == other.collectionId &&
        categoryId == other.categoryId &&
        stalledCoverageDaysThreshold == other.stalledCoverageDaysThreshold;
  }

  @override
  int get hashCode => Object.hash(
    companyId,
    year,
    month,
    warehouseId,
    collectionId,
    categoryId,
    stalledCoverageDaysThreshold,
  );
}
