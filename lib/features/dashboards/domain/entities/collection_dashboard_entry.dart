import 'executive_dashboard_metric.dart';
import 'collection_dashboard_category_mix.dart';

/// One Collection's worth of comparable KPIs for the Collection Dashboard
/// (TASK-138, seção 12.1 de `tasks.md`) — faturamento, quantidade vendida,
/// ticket médio, margem, mix médio de categorias e sell-through, all
/// computed by `LoadCollectionDashboardEntriesUseCase` over exactly
/// [periodStart]–[periodEnd] (the Collection's own `startDate`/`endDate`,
/// TASK-066), so a side-by-side comparison of two [CollectionDashboardEntry]
/// never silently mixes different-length periods (this task's own "Regras
/// de negócio e restrições": "deixar explícito o período de cada").
final class CollectionDashboardEntry {
  const CollectionDashboardEntry({
    required this.collectionId,
    required this.collectionName,
    required this.seasonId,
    required this.year,
    required this.periodStart,
    required this.periodEnd,
    required this.hasDefinedPeriod,
    required this.revenueGross,
    required this.revenueNet,
    required this.quantitySold,
    required this.orderCount,
    required this.discountAmount,
    required this.categoryMix,
    required this.sellThrough,
    required this.margin,
  });

  /// Builds the placeholder entry for a Collection whose `startDate` is not
  /// set (TASK-066: both `startDate`/`endDate` are optional) — never a guess
  /// at a period the Organization itself never declared. Every numeric KPI
  /// stays [ExecutiveDashboardMetric.notCalculated]; the presentation layer
  /// renders "período não definido" instead of a chart/table for this entry.
  factory CollectionDashboardEntry.undefinedPeriod({
    required String collectionId,
    required String collectionName,
    required String? seasonId,
    required int? year,
  }) {
    return CollectionDashboardEntry(
      collectionId: collectionId,
      collectionName: collectionName,
      seasonId: seasonId,
      year: year,
      periodStart: null,
      periodEnd: null,
      hasDefinedPeriod: false,
      revenueGross: 0,
      revenueNet: 0,
      quantitySold: 0,
      orderCount: 0,
      discountAmount: 0,
      categoryMix: const <CollectionDashboardCategoryMix>[],
      sellThrough: const ExecutiveDashboardMetric.notCalculated(),
      margin: const ExecutiveDashboardMetric.notCalculated(),
    );
  }

  final String collectionId;
  final String collectionName;
  final String? seasonId;
  final int? year;

  /// The Collection's own `startDate`/`endDate` (TASK-066) — never a
  /// filter-picked calendar month like `ProductDashboardFilters`/
  /// `SalesDashboardFilters` use, because a Collection's commercial life
  /// rarely aligns with calendar-month boundaries and this task's own rule
  /// requires each compared entry to show *its own* real period.
  final DateTime? periodStart;
  final DateTime? periodEnd;

  /// `false` only when [periodStart] is `null` — see
  /// [CollectionDashboardEntry.undefinedPeriod].
  final bool hasDefinedPeriod;

  final double revenueGross;
  final double revenueNet;
  final int quantitySold;
  final int orderCount;
  final double discountAmount;

  /// "Mix médio de categorias dentro da coleção" — each category's share of
  /// [revenueNet], summing to `100` (or empty, when [hasSalesData] is
  /// `false`).
  final List<CollectionDashboardCategoryMix> categoryMix;

  /// TASK-090's saldo real de estoque via `StockTurnoverMetricScope
  /// .collection` (`GetStockTurnoverMetricsUseCase`, TASK-094) — "percentual
  /// do estoque inicial da coleção já vendido" (this task's own escopo
  /// técnico), stored as `0`–`100`, never estimated without that real stock
  /// baseline (this task's own "nunca estimado sem base real de estoque").
  final ExecutiveDashboardMetric sellThrough;

  /// Always [ExecutiveDashboardMetric.notCalculated]: no cost field exists
  /// anywhere in the domain to derive margin from, same documented gap
  /// `ProductDashboardSnapshot.margin`/`SalesDashboardSnapshot.margin`
  /// already carry.
  final ExecutiveDashboardMetric margin;

  double get averageTicket => orderCount == 0 ? 0 : revenueNet / orderCount;

  double get discountPercentage =>
      revenueGross == 0 ? 0 : (discountAmount / revenueGross) * 100;

  bool get hasSalesData => quantitySold > 0 || orderCount > 0;

  @override
  bool operator ==(Object other) {
    return other is CollectionDashboardEntry &&
        collectionId == other.collectionId &&
        collectionName == other.collectionName &&
        seasonId == other.seasonId &&
        year == other.year &&
        periodStart == other.periodStart &&
        periodEnd == other.periodEnd &&
        hasDefinedPeriod == other.hasDefinedPeriod &&
        revenueGross == other.revenueGross &&
        revenueNet == other.revenueNet &&
        quantitySold == other.quantitySold &&
        orderCount == other.orderCount &&
        discountAmount == other.discountAmount &&
        _listEquals(categoryMix, other.categoryMix) &&
        sellThrough == other.sellThrough &&
        margin == other.margin;
  }

  @override
  int get hashCode => Object.hash(
    collectionId,
    collectionName,
    seasonId,
    year,
    periodStart,
    periodEnd,
    hasDefinedPeriod,
    revenueGross,
    revenueNet,
    quantitySold,
    orderCount,
    discountAmount,
    Object.hashAll(categoryMix),
    sellThrough,
    margin,
  );
}

bool _listEquals(
  List<CollectionDashboardCategoryMix> a,
  List<CollectionDashboardCategoryMix> b,
) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
