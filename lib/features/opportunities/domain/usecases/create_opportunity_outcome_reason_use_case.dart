import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/opportunity_outcome_reason.dart';
import '../repositories/opportunity_outcome_reason_repository.dart';
import '../value_objects/opportunity_outcome_type.dart';
import 'opportunity_outcome_reason_use_case_helpers.dart';

@injectable
final class CreateOpportunityOutcomeReasonUseCase {
  CreateOpportunityOutcomeReasonUseCase(this._repository);

  final OpportunityOutcomeReasonRepository _repository;

  Future<AppResult<OpportunityOutcomeReason>> call({
    required String id,
    required String organizationId,
    required OpportunityOutcomeType type,
    required String description,
    required String createdBy,
  }) async {
    final trimmedId = id.trim();
    final trimmedOrganizationId = organizationId.trim();
    final trimmedDescription = normalizeOutcomeDescription(description);
    final trimmedCreatedBy = createdBy.trim();
    final fieldErrors = <String, String>{};

    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedDescription.isEmpty) {
      fieldErrors['description'] = 'Description is required.';
    }
    if (trimmedCreatedBy.isEmpty) {
      fieldErrors['createdBy'] = 'CreatedBy is required.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<OpportunityOutcomeReason>(
        ValidationFailure(
          'Invalid opportunity outcome reason creation payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_opportunity_outcome_reason_create_payload',
        ),
      );
    }

    final existingResult = await _repository.listByOrganization(
      organizationId: trimmedOrganizationId,
      type: type,
      includeInactive: true,
    );
    if (existingResult is AppFailure<List<OpportunityOutcomeReason>>) {
      return AppFailure<OpportunityOutcomeReason>(existingResult.failure);
    }
    final existingReasons =
        (existingResult as AppSuccess<List<OpportunityOutcomeReason>>).value;
    final normalizedDescription = trimmedDescription.toLowerCase();
    if (existingReasons.any(
      (reason) =>
          reason.description.trim().toLowerCase() == normalizedDescription,
    )) {
      return const AppFailure<OpportunityOutcomeReason>(
        ConflictFailure(
          'Outcome reason already exists for this type.',
          code: 'duplicate_opportunity_outcome_reason',
        ),
      );
    }

    final now = DateTime.now().toUtc();
    final reason = OpportunityOutcomeReason(
      id: trimmedId,
      organizationId: trimmedOrganizationId,
      type: type,
      description: trimmedDescription,
      isActive: true,
      createdAt: now,
      createdBy: trimmedCreatedBy,
      updatedAt: now,
      updatedBy: trimmedCreatedBy,
      version: 1,
    );

    return _repository.create(reason: reason);
  }
}
