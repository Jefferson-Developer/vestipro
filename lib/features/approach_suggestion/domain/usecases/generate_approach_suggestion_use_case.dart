import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/approach_suggestion.dart';
import '../repositories/approach_suggestion_repository.dart';

/// Requests TASK-187's "sugestão de abordagem comercial" (EPIC-28) for one
/// customer. Input validation only — the real authorization boundary is
/// server-side (`suggestApproach`'s own `assertCanAccessCustomer`, always
/// re-validated regardless of what the UI enforces): both entry points this
/// feature is reached from (`CustomerDetailPage`, TASK-052; the central de
/// oportunidades, TASK-132) already gate the surrounding screen/row to a
/// customer the caller is already allowed to see, so this use case does not
/// duplicate a separate client-side visibility check the way
/// `GenerateWalletSummaryUseCase` (TASK-186) does for a *seller's* wallet.
@injectable
final class GenerateApproachSuggestionUseCase {
  const GenerateApproachSuggestionUseCase(
    this._repository,
    this._analyticsService,
  );

  final ApproachSuggestionRepository _repository;
  final AnalyticsService _analyticsService;

  Future<AppResult<ApproachSuggestion>> call({
    required String organizationId,
    required String companyId,
    required String customerId,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedCompanyId = companyId.trim();
    final trimmedCustomerId = customerId.trim();

    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedCompanyId.isEmpty) {
      fieldErrors['companyId'] = 'CompanyId is required.';
    }
    if (trimmedCustomerId.isEmpty) {
      fieldErrors['customerId'] = 'CustomerId is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<ApproachSuggestion>(
        ValidationFailure(
          'Invalid approach suggestion request.',
          fieldErrors: fieldErrors,
          code: 'invalid_approach_suggestion_request',
        ),
      );
    }

    final result = await _repository.generate(
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
      customerId: trimmedCustomerId,
    );
    switch (result) {
      case AppSuccess<ApproachSuggestion>(value: final suggestion):
        await _analyticsService.logEvent(
          AnalyticsEvents.approachSuggestionGenerated,
          parameters: <String, Object?>{
            'organization_id': trimmedOrganizationId,
            'customer_id': trimmedCustomerId,
            'from_cache': suggestion.fromCache,
          },
        );
      case AppFailure<ApproachSuggestion>(failure: final failure):
        await _analyticsService.logEvent(
          AnalyticsEvents.approachSuggestionGenerationFailed,
          parameters: <String, Object?>{
            'organization_id': trimmedOrganizationId,
            'customer_id': trimmedCustomerId,
            'failure_code': failure.code,
          },
        );
    }
    return result;
  }
}
