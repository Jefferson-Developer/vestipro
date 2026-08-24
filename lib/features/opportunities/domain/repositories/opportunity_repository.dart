import '../../../../core/utils/utils.dart';
import '../entities/opportunity.dart';

/// Domain contract for Opportunity persistence, decoupled from
/// Firestore/Drift.
///
/// TASK-057 models the entity and the stage/status use cases with only
/// [create]/[update]/[getById] as a contract-only repository, no concrete
/// implementation — mirroring the precedent set by `LeadRepository` in
/// TASK-055. Listing/pagination for a pipeline/kanban view is left for the
/// funnel task (TASK-058).
abstract interface class OpportunityRepository {
  Future<AppResult<Opportunity>> create({required Opportunity opportunity});

  Future<AppResult<Opportunity>> update({required Opportunity opportunity});

  Future<AppResult<Opportunity>> getById({
    required String organizationId,
    required String id,
  });
}
