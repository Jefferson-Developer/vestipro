import '../../../../core/utils/utils.dart';
import '../entities/opportunity.dart';

/// Domain contract for Opportunity persistence, decoupled from
/// Firestore/Drift.
///
/// TASK-057 modeled the entity and the stage/status use cases with only
/// [create]/[update]/[getById] as a contract-only repository, no concrete
/// implementation — mirroring the precedent set by `LeadRepository` in
/// TASK-055. TASK-058 adds [listByOrganization] for the pipeline/kanban
/// board, along with the first concrete implementation
/// (`SharedPreferencesOpportunityRepository`).
abstract interface class OpportunityRepository {
  Future<AppResult<Opportunity>> create({required Opportunity opportunity});

  Future<AppResult<Opportunity>> update({required Opportunity opportunity});

  Future<AppResult<Opportunity>> getById({
    required String organizationId,
    required String id,
  });

  /// Every Opportunity in [organizationId] (optionally narrowed to
  /// [companyId] and/or [responsibleUserIds]), for the pipeline board
  /// (TASK-058) to group by stage. An empty [responsibleUserIds] means "no
  /// responsible-based restriction" — the caller (`SalesPipelineBloc`'s
  /// host) is responsible for passing the current user's own id there when
  /// the RBAC scope is "own portfolio only", mirroring how
  /// `ListLeadsUseCase.filters.responsibleUserIds` is used (TASK-056); a
  /// full automatic team/portfolio visibility resolution like
  /// `PortfolioVisibilityService` (customers) is out of this task's scope.
  Future<AppResult<List<Opportunity>>> listByOrganization({
    required String organizationId,
    String? companyId,
    Set<String> responsibleUserIds,
  });
}
