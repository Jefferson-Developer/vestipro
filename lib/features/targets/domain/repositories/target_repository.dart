import '../../../../core/utils/utils.dart';
import '../entities/target.dart';
import '../value_objects/target_dimension_type.dart';
import '../value_objects/target_metric_type.dart';

/// Domain contract for Target persistence, decoupled from Firestore/Drift.
///
/// TASK-114 models the entity and this contract only, no concrete
/// implementation — mirroring the precedent set by `OpportunityRepository` in
/// TASK-057. A concrete implementation (e.g. a Firestore-backed one wired to
/// the Outbox, or an interim local store) is expected to arrive with the
/// cadastro de metas flow (TASK-115), the same way `OpportunityRepository`
/// got `SharedPreferencesOpportunityRepository` in TASK-058.
abstract interface class TargetRepository {
  Future<AppResult<Target>> create({required Target target});

  Future<AppResult<Target>> update({required Target target});

  Future<AppResult<Target>> getById({
    required String organizationId,
    required String id,
  });

  /// Every non-deleted Target for [organizationId] (optionally narrowed to
  /// [companyId]) matching [dimensionType]/[dimensionId] and, when supplied,
  /// [metricType] — the "metas ativas de um vendedor no mês corrente" /
  /// "metas de uma equipe no trimestre" query this task's spec asks for.
  ///
  /// Returns every period for that dimension/metric (not just the active
  /// ones), so `CreateTargetUseCase` can run its own overlap/status filtering
  /// over the full candidate set without a second round trip — a concrete
  /// implementation is free to push a period-range filter down to its
  /// datasource as an optimization as long as it never *narrows* what an
  /// unfiltered call here would return.
  Future<AppResult<List<Target>>> listByDimension({
    required String organizationId,
    String? companyId,
    required TargetDimensionType dimensionType,
    required String dimensionId,
    TargetMetricType? metricType,
  });
}
