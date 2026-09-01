import 'package:freezed_annotation/freezed_annotation.dart';

import '../target_period_overlap.dart';
import '../value_objects/target_dimension_type.dart';
import '../value_objects/target_metric_type.dart';
import '../value_objects/target_period_granularity.dart';
import '../value_objects/target_status.dart';
import '../value_objects/target_sync_status.dart';

part 'target.freezed.dart';

/// A commercial goal ("meta") for EPIC-15 (`tasks.md`, VESTI-085/VESTI-086):
/// a [targetValue] of [metricType] to reach over a period, for one
/// [dimensionType]/[dimensionId] combination (a sales rep, a team, a company,
/// a collection or a category).
///
/// This entity is deliberately only the *definition* of a goal — it never
/// computes achievement/progress/gap/projection itself (that is TASK-116's
/// dashboard, reading server-side aggregations per the BI rule in
/// `AGENTS.md`, never recomputing dozens of client queries). `TargetsTable`
/// keeps a server-computed `achievedValueCache` for that dashboard, but it is
/// intentionally not part of this domain entity.
///
/// The tenant field [organizationId] and [companyId] are immutable after
/// creation, resolved from the authenticated session — never from a form
/// field, same rule as `Opportunity.organizationId`.
///
/// Two targets are only mutually exclusive (same dimension/metric, no
/// overlapping period) while both are [TargetStatus.active] — enforced by
/// `CreateTargetUseCase`, not by this entity, since checking it requires
/// querying other targets via `TargetRepository`. [overlapsWith] is the
/// reusable period-comparison primitive that use case calls once per
/// candidate.
@freezed
abstract class Target with _$Target {
  const Target._();

  const factory Target({
    required String id,
    required String organizationId,
    required String companyId,
    required TargetDimensionType dimensionType,
    required String dimensionId,
    required TargetPeriodGranularity periodGranularity,
    required DateTime startDate,
    required DateTime endDate,
    required TargetMetricType metricType,
    required double targetValue,
    required String currency,
    required TargetStatus status,
    required DateTime createdAt,
    required String createdBy,
    required DateTime updatedAt,
    required String updatedBy,
    DateTime? deletedAt,
    required int version,
    required TargetSyncStatus syncStatus,
  }) = _Target;

  /// Whether [startDate]..[endDate] overlaps [other]'s period. Callers are
  /// responsible for first narrowing candidates to the same
  /// `organizationId`/`companyId`/[dimensionType]/[dimensionId]/[metricType]
  /// (typically via `TargetRepository.listByDimension`) — this method only
  /// ever compares the period, never the dimension/metric.
  bool overlapsWith(Target other) {
    return targetPeriodsOverlap(
      aStart: startDate,
      aEnd: endDate,
      bStart: other.startDate,
      bEnd: other.endDate,
    );
  }
}
