import '../../../../core/utils/utils.dart';
import '../entities/opportunity_outcome_reason.dart';
import '../value_objects/opportunity_outcome_type.dart';

abstract interface class OpportunityOutcomeReasonRepository {
  Future<AppResult<OpportunityOutcomeReason>> create({
    required OpportunityOutcomeReason reason,
  });

  Future<AppResult<OpportunityOutcomeReason>> update({
    required OpportunityOutcomeReason reason,
  });

  Future<AppResult<OpportunityOutcomeReason>> getById({
    required String organizationId,
    required String id,
  });

  Future<AppResult<List<OpportunityOutcomeReason>>> listByOrganization({
    required String organizationId,
    OpportunityOutcomeType? type,
    bool includeInactive,
  });
}
