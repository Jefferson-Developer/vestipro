import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../audit_log/domain/audit_log_entry_factory.dart';
import '../../../audit_log/domain/entities/audit_log_entry.dart';
import '../../../audit_log/domain/repositories/audit_log_repository.dart';
import '../../../audit_log/domain/value_objects/audit_action.dart';
import '../entities/membership.dart';
import '../repositories/membership_repository.dart';

/// Assigns [roleId]/[roleName] to [userId] within [organizationId]
/// (`tasks.md`, seção 3.3): creates a brand new [Membership] when the user
/// has none yet, or updates the [roleId]/[roleName] of the existing one
/// otherwise — [Membership.teamIds] and [Membership.status] are preserved
/// as-is in that case.
///
/// Whether the acting user ([updatedBy]) is allowed to grant [roleId] is
/// RBAC's job (TASK-029), not this use case's — every `Failure` returned by
/// the repository (including a `NotFoundFailure` when [organizationId]
/// itself does not exist) is propagated unchanged.
///
/// Every successful role change is also recorded in the central audit log
/// (`AuditAction.roleChanged`, TASK-033) via [AuditLogRepository] directly
/// (built through [AuditLogEntryFactory], the same factory
/// `RecordAuditLogUseCase` uses — see its docs for why this use case does
/// not depend on `RecordAuditLogUseCase` itself) — this is the "ação
/// administrativa sensível já existente" the task's acceptance criteria
/// requires to be populated. [actorName] is a snapshot of the acting user's
/// display name at this exact moment (see `AuditLogEntry.actorName` docs on
/// why it is kept separate from [updatedBy]/the actor's uid). If recording
/// the audit entry itself fails, this use case propagates that failure
/// instead of silently discarding it (`tasks.md`, seção 13: "nenhuma dessas
/// ações pode passar em silêncio") — even though, today, the Membership
/// write and the audit write are not atomic (see `RecordAuditLogUseCase`
/// docs for the Cloud Function migration plan that would close this gap).
@injectable
final class AssignRoleToUserUseCase {
  const AssignRoleToUserUseCase(this._repository, this._auditLogRepository);

  final MembershipRepository _repository;
  final AuditLogRepository _auditLogRepository;

  Future<AppResult<Membership>> call({
    required String organizationId,
    required String userId,
    required String roleId,
    required String roleName,
    required String updatedBy,
    required String actorName,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedUserId = userId.trim();
    final trimmedRoleId = roleId.trim();
    final trimmedRoleName = roleName.trim();
    final trimmedUpdatedBy = updatedBy.trim();
    final trimmedActorName = actorName.trim();

    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedUserId.isEmpty) fieldErrors['userId'] = 'UserId is required.';
    if (trimmedRoleId.isEmpty) fieldErrors['roleId'] = 'RoleId is required.';
    if (trimmedRoleName.isEmpty) {
      fieldErrors['roleName'] = 'RoleName is required.';
    }
    if (trimmedUpdatedBy.isEmpty) {
      fieldErrors['updatedBy'] = 'UpdatedBy is required.';
    }
    if (trimmedActorName.isEmpty) {
      fieldErrors['actorName'] = 'ActorName is required.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<Membership>(
        ValidationFailure(
          'Invalid assign-role-to-user payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_assign_role_to_user_payload',
        ),
      );
    }

    final currentResult = await _repository.getByUser(
      organizationId: trimmedOrganizationId,
      userId: trimmedUserId,
    );

    Map<String, Object?>? previousValue;
    AppResult<Membership> mutationResult;

    if (currentResult is AppFailure<Membership>) {
      if (currentResult.failure is! NotFoundFailure) {
        return currentResult;
      }

      mutationResult = await _repository.create(
        organizationId: trimmedOrganizationId,
        userId: trimmedUserId,
        roleId: trimmedRoleId,
        roleName: trimmedRoleName,
        createdBy: trimmedUpdatedBy,
      );
    } else {
      final current = (currentResult as AppSuccess<Membership>).value;
      previousValue = <String, Object?>{
        'roleId': current.roleId,
        'roleName': current.roleName,
      };
      mutationResult = await _repository.update(
        organizationId: trimmedOrganizationId,
        userId: trimmedUserId,
        roleId: trimmedRoleId,
        roleName: trimmedRoleName,
        teamIds: current.teamIds,
        status: current.status,
        updatedBy: trimmedUpdatedBy,
      );
    }

    if (mutationResult is AppFailure<Membership>) return mutationResult;

    final auditEntry = AuditLogEntryFactory.build(
      organizationId: trimmedOrganizationId,
      actorUserId: trimmedUpdatedBy,
      actorName: trimmedActorName,
      action: AuditAction.roleChanged,
      entityType: 'membership',
      entityId: trimmedUserId,
      previousValue: previousValue,
      newValue: <String, Object?>{
        'roleId': trimmedRoleId,
        'roleName': trimmedRoleName,
      },
    );
    final auditResult = await _auditLogRepository.record(auditEntry);

    if (auditResult is AppFailure<AuditLogEntry>) {
      return AppFailure<Membership>(auditResult.failure);
    }

    return mutationResult;
  }
}
