import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/opportunity.dart';
import '../repositories/opportunity_repository.dart';
import '../value_objects/opportunity_sync_status.dart';

/// Recomputes and persists [Opportunity.revenueForecast] from the current
/// [Opportunity.estimatedValue] and [Opportunity.probability].
///
/// `revenueForecast` is a derived, stored value (see the class doc on
/// [Opportunity]) rather than one computed on every read, so it can be
/// queried/aggregated directly in pipeline reports. Whenever a future use
/// case changes `estimatedValue` or `probability` directly on the
/// repository, it must call this use case afterwards (or inline the same
/// formula) to keep the stored forecast from drifting.
final class RecalculateRevenueForecastUseCase {
  RecalculateRevenueForecastUseCase(this._repository);

  final OpportunityRepository _repository;

  Future<AppResult<Opportunity>> call({
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
      return AppFailure<Opportunity>(
        ValidationFailure(
          'Invalid opportunity revenue recalculation payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_opportunity_recalculate_payload',
        ),
      );
    }

    final opportunityResult = await _repository.getById(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
    );
    if (opportunityResult is AppFailure<Opportunity>) return opportunityResult;
    final opportunity = (opportunityResult as AppSuccess<Opportunity>).value;

    final recalculatedForecast = opportunity.calculateRevenueForecast();
    if (recalculatedForecast == opportunity.revenueForecast) {
      return AppSuccess<Opportunity>(opportunity);
    }

    final now = DateTime.now().toUtc();
    final updated = opportunity.copyWith(
      revenueForecast: recalculatedForecast,
      updatedAt: now,
      updatedBy: trimmedUpdatedBy,
      version: opportunity.version + 1,
      syncStatus: OpportunitySyncStatus.pending,
    );

    return _repository.update(opportunity: updated);
  }
}
