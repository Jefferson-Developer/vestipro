import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/opportunity_outcome_reason.dart';
import '../repositories/opportunity_outcome_reason_repository.dart';
import '../value_objects/opportunity_outcome_type.dart';

@injectable
final class ListOpportunityOutcomeReasonsUseCase {
  ListOpportunityOutcomeReasonsUseCase(this._repository);

  final OpportunityOutcomeReasonRepository _repository;

  Future<AppResult<List<OpportunityOutcomeReason>>> call({
    required String organizationId,
    OpportunityOutcomeType? type,
    bool includeInactive = false,
  }) {
    final trimmedOrganizationId = organizationId.trim();
    if (trimmedOrganizationId.isEmpty) {
      return Future.value(
        const AppFailure<List<OpportunityOutcomeReason>>(
          ValidationFailure(
            'OrganizationId is required.',
            fieldErrors: <String, String>{
              'organizationId': 'OrganizationId is required.',
            },
            code: 'invalid_opportunity_outcome_reason_list_payload',
          ),
        ),
      );
    }

    return _repository.listByOrganization(
      organizationId: trimmedOrganizationId,
      type: type,
      includeInactive: includeInactive,
    );
  }
}
