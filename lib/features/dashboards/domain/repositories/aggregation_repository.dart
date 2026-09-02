import '../../../../core/utils/utils.dart';
import '../entities/aggregation_snapshot.dart';
import '../value_objects/aggregation_dimension.dart';

/// The single read port every dashboard (EPIC-17, TASK-134 a TASK-143) and
/// every EPIC-16 insight rule that needs pre-computed commercial data must
/// go through — never a direct query against raw `orders`/`customers`/
/// `products` (`tasks.md`, seção 22).
///
/// Implementations own the "cache local e TTL" this task's own scope
/// técnico requires (see `AggregationRepositoryImpl`'s own docs for why that
/// cache is in-memory, not Drift-backed, unlike
/// `VariantStockBalanceRepositoryImpl`).
abstract interface class AggregationRepository {
  /// A single snapshot by its exact key, or `null` when the aggregation
  /// layer has not produced one yet for that period (e.g. a brand-new
  /// organization with zero orders this month, or a not-yet-run nightly
  /// batch) — never an error; the caller (a dashboard widget) decides how
  /// to render "sem dados ainda" itself.
  Future<AppResult<AggregationSnapshot?>> getSnapshot({
    required String organizationId,
    required AggregationDimension dimension,
    required String companyId,
    required String scopeId,
    required String periodKey,
  });

  /// Every snapshot of [dimension] for one exact [periodKey] (e.g. every
  /// `productMonthly` snapshot of `2026-08`, for a "top produtos do mês"
  /// ranking widget) — one bounded read, never a fan-out of per-scope
  /// queries.
  Future<AppResult<List<AggregationSnapshot>>> listByPeriod({
    required String organizationId,
    required AggregationDimension dimension,
    required String companyId,
    required String periodKey,
    int limit = 50,
  });

  /// Every snapshot of [dimension] between [fromPeriodKey] and
  /// [toPeriodKey] (inclusive) for a single [scopeId] — the trend-chart
  /// query (e.g. `salesDaily` revenue of one company across the last 30
  /// days).
  Future<AppResult<List<AggregationSnapshot>>> listByPeriodRange({
    required String organizationId,
    required AggregationDimension dimension,
    required String companyId,
    required String scopeId,
    required String fromPeriodKey,
    required String toPeriodKey,
  });
}
