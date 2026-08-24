import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/opportunity_outcome_reason.dart';
import '../repositories/opportunity_outcome_reason_repository.dart';
import '../value_objects/opportunity_outcome_type.dart';

String normalizeOutcomeDescription(String value) => value.trim();

String? normalizeOutcomeNote(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

String? snapshotForOutcomeReason(OpportunityOutcomeReason reason) {
  final snapshot = reason.description.trim();
  return snapshot.isEmpty ? null : snapshot;
}

Failure invalidOpportunityOutcomeReasonFailure({
  required OpportunityOutcomeType expectedType,
  required String reasonId,
  required String message,
  String code = 'invalid_opportunity_outcome_reason',
}) {
  return ValidationFailure(
    message,
    fieldErrors: <String, String>{'reasonId': message},
    code: code,
    cause: <String, String>{
      'expectedType': expectedType.name,
      'reasonId': reasonId,
    },
  );
}

Future<AppResult<OpportunityOutcomeReason>> loadSelectableOutcomeReason({
  required OpportunityOutcomeReasonRepository repository,
  required String organizationId,
  required String reasonId,
  required OpportunityOutcomeType expectedType,
}) async {
  final result = await repository.getById(
    organizationId: organizationId,
    id: reasonId,
  );
  if (result is AppFailure<OpportunityOutcomeReason>) return result;

  final reason = (result as AppSuccess<OpportunityOutcomeReason>).value;
  if (reason.type != expectedType) {
    return AppFailure<OpportunityOutcomeReason>(
      invalidOpportunityOutcomeReasonFailure(
        expectedType: expectedType,
        reasonId: reasonId,
        message: 'Outcome reason type does not match the close action.',
        code: 'opportunity_outcome_reason_type_mismatch',
      ),
    );
  }
  if (!reason.isActive) {
    return AppFailure<OpportunityOutcomeReason>(
      invalidOpportunityOutcomeReasonFailure(
        expectedType: expectedType,
        reasonId: reasonId,
        message: 'Outcome reason is inactive.',
        code: 'inactive_opportunity_outcome_reason',
      ),
    );
  }

  return AppSuccess<OpportunityOutcomeReason>(reason);
}
