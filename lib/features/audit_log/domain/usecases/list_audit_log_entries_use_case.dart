import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../../core/utils/utils.dart';
import '../entities/audit_log_entry_page.dart';
import '../repositories/audit_log_repository.dart';
import '../value_objects/audit_action.dart';

/// Lists [organizationId]'s audit log for [requestedByUserId], enforcing
/// RBAC in the domain layer as defense-in-depth (`tasks.md`, seção 13):
/// only a caller granted [Capability.auditLogView] — today, `OWNER`/`ADMIN`
/// — ever receives entries; anyone else gets a [PermissionFailure] without
/// the repository/Firestore Security Rules even being asked. Firestore
/// Security Rules remain the real, independent source of truth for this
/// same decision — this check never replaces them.
@injectable
final class ListAuditLogEntriesUseCase {
  const ListAuditLogEntriesUseCase(this._repository, this._permissionService);

  final AuditLogRepository _repository;
  final PermissionService _permissionService;

  Future<AppResult<AuditLogEntryPage>> call({
    required String organizationId,
    required String requestedByUserId,
    int limit = 50,
    DateTime? before,
    DateTime? from,
    DateTime? to,
    Set<AuditAction> actions = const <AuditAction>{},
    String? actorUserId,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedRequestedByUserId = requestedByUserId.trim();
    final trimmedActorUserId = actorUserId?.trim();

    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedRequestedByUserId.isEmpty) {
      fieldErrors['requestedByUserId'] = 'RequestedByUserId is required.';
    }
    if (limit < 1 || limit > 100) {
      fieldErrors['limit'] = 'Limit must be between 1 and 100.';
    }
    if (from != null && to != null && from.isAfter(to)) {
      fieldErrors['period'] = 'From must be before to.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<AuditLogEntryPage>(
        ValidationFailure(
          'Invalid audit log listing request.',
          fieldErrors: fieldErrors,
          code: 'invalid_audit_log_list_request',
        ),
      );
    }

    final permissionResult = await _permissionService.hasPermission(
      organizationId: trimmedOrganizationId,
      userId: trimmedRequestedByUserId,
      capability: Capability.auditLogView,
    );

    if (permissionResult is AppFailure<bool>) {
      return AppFailure<AuditLogEntryPage>(permissionResult.failure);
    }

    final isAllowed = (permissionResult as AppSuccess<bool>).value;
    if (!isAllowed) {
      return AppFailure<AuditLogEntryPage>(
        const PermissionFailure(
          'User is not allowed to view the audit log.',
          code: 'audit_log_view_denied',
        ),
      );
    }

    return _repository.listPageByOrganization(
      organizationId: trimmedOrganizationId,
      limit: limit,
      before: before,
      from: from,
      to: to,
      actions: actions,
      actorUserId: trimmedActorUserId == null || trimmedActorUserId.isEmpty
          ? null
          : trimmedActorUserId,
    );
  }
}
