import '../../../../core/utils/utils.dart';
import '../entities/positivacao_snapshot.dart';
import '../value_objects/positivacao_dimension_type.dart';

/// Domain contract for reading the server-computed positivação snapshot for
/// one carteira/período (TASK-117, EPIC-15/VESTI-087), decoupled from
/// Firestore/Drift — same shape as `TargetAchievementRepository` (TASK-116).
///
/// Never a summation contract: every implementation must resolve
/// [PositivacaoSnapshot] from a value some server-side aggregation already
/// computed (a Cloud Function/BI pipeline reading the carteira/orders — never
/// this app summing raw documents client-side), per the BI aggregation rule
/// in `AGENTS.md`.
abstract interface class PositivacaoRepository {
  /// One-shot read of the current snapshot for
  /// [dimensionType]/[dimensionId]/[periodStart].
  Future<AppResult<PositivacaoSnapshot>> getForDimension({
    required String organizationId,
    required String companyId,
    required PositivacaoDimensionType dimensionType,
    required String dimensionId,
    required DateTime periodStart,
    required DateTime periodEnd,
  });

  /// Near-real-time stream of the same snapshot: emits again whenever the
  /// underlying local cache is refreshed by a future sync pass, without
  /// polling — the mechanism the positivação dashboard's near real-time
  /// refresh is built on, same as `TargetAchievementRepository.watchForTarget`.
  Stream<PositivacaoSnapshot> watchForDimension({
    required String organizationId,
    required String companyId,
    required PositivacaoDimensionType dimensionType,
    required String dimensionId,
    required DateTime periodStart,
    required DateTime periodEnd,
  });
}
