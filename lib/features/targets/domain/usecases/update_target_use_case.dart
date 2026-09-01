import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../../core/utils/utils.dart';
import '../../../audit_log/domain/audit_log_entry_factory.dart';
import '../../../audit_log/domain/entities/audit_log_entry.dart';
import '../../../audit_log/domain/repositories/audit_log_repository.dart';
import '../../../audit_log/domain/value_objects/audit_action.dart';
import '../entities/target.dart';
import '../repositories/target_repository.dart';
import '../target_period_overlap.dart';
import '../value_objects/target_metric_type.dart';
import '../value_objects/target_period_granularity.dart';
import '../value_objects/target_status.dart';
import 'target_use_case_helpers.dart';

/// Edits an existing Target ("meta comercial"), the other half of the
/// cadastro de metas flow (TASK-115, `VESTI-085`) `CreateTargetUseCase`
/// starts.
///
/// [dimensionType]/[dimensionId] are deliberately not parameters here: which
/// vendedor/equipe/empresa/coleção/categoria a Target belongs to is its
/// identity, not an editable field — changing it is creating a different
/// Target, not editing this one (same precedent as `Order.customerId` or
/// `PromotionalCampaign.id` never being update-target fields).
///
/// [updatedBy] doubles as the RBAC actor: [Capability.targetManage] is
/// re-checked here exactly like `CreateTargetUseCase`, never trusted from
/// the UI alone.
///
/// Every successful edit is recorded as an [AuditAction.targetUpdated] audit
/// log entry (`tasks.md`, "Alterações em metas ativas geram registro de
/// auditoria") — unconditionally, not only while [TargetStatus.active], so
/// the trail also covers draft edits.
@injectable
final class UpdateTargetUseCase {
  UpdateTargetUseCase(
    this._repository,
    this._permissionService,
    this._auditLogRepository,
    this._analyticsService,
  );

  final TargetRepository _repository;
  final PermissionService _permissionService;
  final AuditLogRepository _auditLogRepository;
  final AnalyticsService _analyticsService;

  Future<AppResult<Target>> call({
    required String organizationId,
    required String id,
    required TargetPeriodGranularity periodGranularity,
    required DateTime startDate,
    required DateTime endDate,
    required TargetMetricType metricType,
    required double targetValue,
    required String currency,
    required TargetStatus status,
    required String updatedBy,
    required String actorName,

    /// The server-computed `achievedValueCache` known for this Target right
    /// now (TASK-116's dashboard is the only thing that ever calculates it —
    /// this use case never does), when the caller has it at hand. `null`
    /// skips the "reduzir abaixo do realizado" check entirely, since there
    /// is nothing to compare against yet.
    double? currentAchievedValue,

    /// Must be `true` to persist a [targetValue] below [currentAchievedValue]
    /// — set only after the UI has shown the corresponding warning and the
    /// user confirmed it (TASK-115: "alertar antes de reduzir o valor da
    /// meta abaixo do já realizado").
    bool confirmReduceBelowAchieved = false,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedId = id.trim();
    final trimmedCurrency = currency.trim();
    final trimmedUpdatedBy = updatedBy.trim();
    final fieldErrors = <String, String>{};

    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedCurrency.isEmpty) {
      fieldErrors['currency'] = 'Currency is required.';
    }
    if (trimmedUpdatedBy.isEmpty) {
      fieldErrors['updatedBy'] = 'UpdatedBy is required.';
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
          'Invalid target update payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_target_update_payload',
        ),
      );
    }

    final permissionResult = await _permissionService.hasPermission(
      organizationId: trimmedOrganizationId,
      userId: trimmedUpdatedBy,
      capability: Capability.targetManage,
    );
    if (permissionResult is AppFailure<bool>) {
      return AppFailure<Target>(permissionResult.failure);
    }
    if (!(permissionResult as AppSuccess<bool>).value) {
      return AppFailure<Target>(targetManageDeniedFailure());
    }

    final currentResult = await _repository.getById(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
    );
    if (currentResult is AppFailure<Target>) return currentResult;
    final current = (currentResult as AppSuccess<Target>).value;

    if (currentAchievedValue != null &&
        targetValue < currentAchievedValue &&
        !confirmReduceBelowAchieved) {
      return AppFailure<Target>(
        targetValueBelowAchievedFailure(currentAchievedValue),
      );
    }

    if (status == TargetStatus.active) {
      final candidatesResult = await _repository.listByDimension(
        organizationId: trimmedOrganizationId,
        companyId: current.companyId,
        dimensionType: current.dimensionType,
        dimensionId: current.dimensionId,
        metricType: metricType,
      );

      final overlapCheckFailure = candidatesResult.fold(
        onSuccess: (candidates) {
          final hasOverlap = candidates.any(
            (candidate) =>
                candidate.id != current.id &&
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

    final updated = current.copyWith(
      periodGranularity: periodGranularity,
      startDate: startDate,
      endDate: endDate,
      metricType: metricType,
      targetValue: targetValue,
      currency: trimmedCurrency,
      status: status,
      updatedAt: DateTime.now().toUtc(),
      updatedBy: trimmedUpdatedBy,
      version: current.version + 1,
    );

    final result = await _repository.update(target: updated);
    if (result is AppFailure<Target>) return result;

    final auditResult = await _auditLogRepository.record(
      AuditLogEntryFactory.build(
        organizationId: updated.organizationId,
        actorUserId: trimmedUpdatedBy,
        actorName: actorName.trim().isEmpty ? trimmedUpdatedBy : actorName,
        action: AuditAction.targetUpdated,
        entityType: 'target',
        entityId: updated.id,
        previousValue: current.toAuditMap(),
        newValue: updated.toAuditMap(),
      ),
    );
    if (auditResult is AppFailure<AuditLogEntry>) {
      return AppFailure<Target>(auditResult.failure);
    }

    await _analyticsService.logEvent(
      AnalyticsEvents.targetUpdated,
      parameters: <String, Object?>{
        'organization_id': updated.organizationId,
        'company_id': updated.companyId,
        'dimension_type': updated.dimensionType.name,
        'metric_type': updated.metricType.name,
      },
    );

    return result;
  }
}
