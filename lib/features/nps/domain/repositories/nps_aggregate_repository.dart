import '../../../../core/utils/utils.dart';
import '../entities/nps_aggregate_snapshot.dart';
import '../value_objects/nps_aggregate_scope.dart';

/// The single read port `NpsScoreCard` (TASK-202, EPIC-30) goes through —
/// never a client-side query/sum over raw `npsResponses` (`tasks.md`:
/// "cálculo de NPS agregado... nunca recalculado ad hoc no cliente"). Same
/// contract shape as `dashboards/domain/repositories/
/// aggregation_repository.dart` (TASK-133), kept as its own dedicated
/// repository rather than folded into that one: `AggregationSnapshot`'s own
/// shape (revenue/order-count/quantity) has no natural field for
/// promoters/passives/detractors/NPS score, and repurposing one of its
/// existing numeric fields to mean something entirely different would be
/// exactly the kind of undocumented field reuse this codebase avoids.
abstract interface class NpsAggregateRepository {
  /// A single snapshot by its exact key, or `null` when the aggregation
  /// layer has not produced one yet for that period (e.g. no NPS response
  /// received yet this month) — never an error.
  Future<AppResult<NpsAggregateSnapshot?>> getSnapshot({
    required String organizationId,
    required String companyId,
    required NpsAggregateScope scope,
    required String scopeId,
    required String periodKey,
  });
}
