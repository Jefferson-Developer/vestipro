import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/opportunity_outcome_reason.dart';
import '../repositories/opportunity_outcome_reason_repository.dart';

@injectable
final class DeactivateOpportunityOutcomeReasonUseCase {
  DeactivateOpportunityOutcomeReasonUseCase(this._repository);

  final OpportunityOutcomeReasonRepository _repository;

  Future<AppResult<OpportunityOutcomeReason>> call({
    required String organizationId,
    required String id,
    required String updatedBy,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedId = id.trim();
    final trimmedUpdatedBy = updatedBy.trim();
    final fieldErrors = <String, String>{};

    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedUpdatedBy.isEmpty) {
      fieldErrors['updatedBy'] = 'UpdatedBy is required.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<OpportunityOutcomeReason>(
        ValidationFailure(
          'Invalid opportunity outcome reason deactivation payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_opportunity_outcome_reason_deactivate_payload',
        ),
      );
    }

    final currentResult = await _repository.getById(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
    );
    if (currentResult is AppFailure<OpportunityOutcomeReason>) {
      return currentResult;
    }
    final current =
        (currentResult as AppSuccess<OpportunityOutcomeReason>).value;
    if (!current.isActive) return AppSuccess<OpportunityOutcomeReason>(current);

    final now = DateTime.now().toUtc();
    return _repository.update(
      reason: current.copyWith(
        isActive: false,
        updatedAt: now,
        updatedBy: trimmedUpdatedBy,
        version: current.version + 1,
      ),
    );
  }
}
