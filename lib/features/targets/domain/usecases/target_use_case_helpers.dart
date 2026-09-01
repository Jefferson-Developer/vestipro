import '../../../../core/errors/errors.dart';

String? normalizeTargetOptional(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

/// Builds the failure returned when `CreateTargetUseCase` finds another
/// active Target whose period overlaps the one being created, for the same
/// dimension/metric.
Failure targetPeriodOverlapFailure() {
  return const ValidationFailure(
    'Another active target already covers part of this period for this '
    'dimension and metric.',
    fieldErrors: <String, String>{
      'startDate': 'Overlapping active target exists for this period.',
    },
    code: 'target_period_overlap',
  );
}

/// Returned by `CreateTargetUseCase`/`UpdateTargetUseCase` when the actor
/// lacks `Capability.targetManage` (`tasks.md`, VESTI-085): only
/// OWNER/ADMIN/SALES_MANAGER may create or edit a Target today, `SALES_REP`
/// included — see `Capability.targetManage`'s docs for why a `SALES_REP`
/// cannot self-edit their own Target yet either.
Failure targetManageDeniedFailure() {
  return const PermissionFailure(
    'User is not allowed to create or edit targets.',
    code: 'target_manage_denied',
  );
}

/// Returned by `UpdateTargetUseCase` when lowering `targetValue` would put
/// it below [currentAchievedValue] without the caller having already
/// confirmed that reduction (`confirmReduceBelowAchieved: true`) — the
/// "alertar antes de reduzir o valor da meta abaixo do já realizado" rule
/// from TASK-115's spec. Never blocks raising the value, nor lowering it
/// above what was already achieved.
Failure targetValueBelowAchievedFailure(double currentAchievedValue) {
  return ValidationFailure(
    'The new targetValue is below the amount already achieved for this '
    'target ($currentAchievedValue). Confirm to proceed anyway.',
    fieldErrors: const <String, String>{
      'targetValue': 'Novo valor é menor que o já realizado nesta meta.',
    },
    code: 'target_value_below_achieved',
  );
}
