import '../value_objects/nps_aggregate_scope.dart';

/// One pre-computed `npsMonthlyAggregates` snapshot (TASK-202, EPIC-30) — a
/// single row of promoters/passives/detractors/NPS score already aggregated
/// server-side by `recomputeNpsMonthlyAggregates`
/// (`functions/src/nps/recompute-nps-monthly-aggregates.ts`), read directly
/// by a dashboard instead of ever recomputing it client-side (`tasks.md`:
/// "nunca recalculado ad hoc no cliente").
final class NpsAggregateSnapshot {
  const NpsAggregateSnapshot({
    required this.organizationId,
    required this.companyId,
    required this.scope,
    required this.scopeId,
    required this.periodKey,
    required this.promoters,
    required this.passives,
    required this.detractors,
    required this.totalResponses,
    required this.npsScore,
    required this.generatedAt,
    required this.version,
  });

  final String organizationId;
  final String companyId;
  final NpsAggregateScope scope;

  /// `companyId` itself for [NpsAggregateScope.organization]; `sellerId`/
  /// `teamId` otherwise.
  final String scopeId;

  /// `YYYY-MM`.
  final String periodKey;

  final int promoters;
  final int passives;
  final int detractors;
  final int totalResponses;

  /// `null` (never `0`/`NaN`) when [totalResponses] is zero — an empty
  /// period has no score to show, not a score of zero (same "sem dados
  /// suficientes" empty state every dashboard indicator in this codebase
  /// already renders for a `notCalculated` metric).
  final double? npsScore;

  final DateTime generatedAt;
  final int version;
}
