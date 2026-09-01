import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/target.dart';
import '../repositories/target_repository.dart';
import '../target_period_overlap.dart';
import '../value_objects/target_dimension_type.dart';
import '../value_objects/target_metric_type.dart';
import '../value_objects/target_period_granularity.dart';
import '../value_objects/target_status.dart';
import '../value_objects/target_sync_status.dart';
import 'target_use_case_helpers.dart';

/// Creates a Target ("meta comercial"), anticipating the cadastro de metas
/// flow (TASK-115, `VESTI-085`).
///
/// Field validation covers the rules `Target`'s own docs describe as this use
/// case's job (never the entity's, since the entity has no repository
/// access): [targetValue] must not be negative, [startDate] must be strictly
/// before [endDate], and — only when [status] is [TargetStatus.active] — no
/// other *active* Target for the same [organizationId]/[companyId]/
/// [dimensionType]/[dimensionId]/[metricType] may have an overlapping period.
/// A [TargetStatus.draft] target skips the overlap check entirely: it is not
/// yet competing for that period/dimension slot.
final class CreateTargetUseCase {
  CreateTargetUseCase(this._repository);

  final TargetRepository _repository;

  Future<AppResult<Target>> call({
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
    String currency = 'BRL',
    TargetStatus status = TargetStatus.active,
    required String createdBy,
  }) async {
    final trimmedId = id.trim();
    final trimmedOrganizationId = organizationId.trim();
    final trimmedCompanyId = companyId.trim();
    final trimmedDimensionId = dimensionId.trim();
    final trimmedCurrency = currency.trim();
    final trimmedCreatedBy = createdBy.trim();
    final fieldErrors = <String, String>{};

    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedCompanyId.isEmpty) {
      fieldErrors['companyId'] = 'CompanyId is required.';
    }
    if (trimmedDimensionId.isEmpty) {
      fieldErrors['dimensionId'] = 'DimensionId is required.';
    }
    if (trimmedCurrency.isEmpty) {
      fieldErrors['currency'] = 'Currency is required.';
    }
    if (trimmedCreatedBy.isEmpty) {
      fieldErrors['createdBy'] = 'CreatedBy is required.';
    }
    if (targetValue < 0) {
      fieldErrors['targetValue'] = 'TargetValue cannot be negative.';
    }
    if (!startDate.isBefore(endDate)) {
      fieldErrors['endDate'] = 'EndDate must be after startDate.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<Target>(
        ValidationFailure(
          'Invalid target creation payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_target_create_payload',
        ),
      );
    }

    if (status == TargetStatus.active) {
      final candidatesResult = await _repository.listByDimension(
        organizationId: trimmedOrganizationId,
        companyId: trimmedCompanyId,
        dimensionType: dimensionType,
        dimensionId: trimmedDimensionId,
        metricType: metricType,
      );

      final overlapCheckFailure = candidatesResult.fold(
        onSuccess: (candidates) {
          final hasOverlap = candidates.any(
            (candidate) =>
                candidate.status == TargetStatus.active &&
                candidate.deletedAt == null &&
                targetPeriodsOverlap(
                  aStart: candidate.startDate,
                  aEnd: candidate.endDate,
                  bStart: startDate,
                  bEnd: endDate,
                ),
          );
          return hasOverlap ? targetPeriodOverlapFailure() : null;
        },
        onFailure: (failure) => failure,
      );

      if (overlapCheckFailure != null) {
        return AppFailure<Target>(overlapCheckFailure);
      }
    }

    final now = DateTime.now().toUtc();
    final target = Target(
      id: trimmedId,
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
      dimensionType: dimensionType,
      dimensionId: trimmedDimensionId,
      periodGranularity: periodGranularity,
      startDate: startDate,
      endDate: endDate,
      metricType: metricType,
      targetValue: targetValue,
      currency: trimmedCurrency,
      status: status,
      createdAt: now,
      createdBy: trimmedCreatedBy,
      updatedAt: now,
      updatedBy: trimmedCreatedBy,
      version: 1,
      syncStatus: TargetSyncStatus.pending,
    );

    return _repository.create(target: target);
  }
}
