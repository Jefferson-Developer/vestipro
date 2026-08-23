import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../audit_log_entry_factory.dart';
import '../entities/audit_log_entry.dart';
import '../repositories/audit_log_repository.dart';
import '../value_objects/audit_action.dart';

/// Records one sensitive administrative action into the central audit log
/// (`tasks.md`, seções 13 e 20; TASK-033) — every feature that performs an
/// action from [AuditAction] and does not already depend on
/// [AuditLogRepository] directly should call this instead of writing to it,
/// so validation, id/timestamp generation and sensitive-value stripping
/// (see [AuditLogEntryFactory]) never gets reimplemented (or forgotten)
/// call-site by call-site.
///
/// **Known limitation (documented, not silent):** this use case is called
/// from the client, right after the sensitive action itself succeeds (e.g.
/// `AssignRoleToUserUseCase`) — the same pattern `CreateOrganizationUseCase`
/// already uses for onboarding (see `firestore.rules` comments). It is not
/// yet backed by a Cloud Function/Firestore trigger that would guarantee an
/// entry even if a write bypassed the use case entirely. Firestore Security
/// Rules only allow `create` (never `update`/`delete`, for anyone), which
/// bounds the damage, but do not by themselves guarantee that every
/// sensitive write is *always* accompanied by a log entry. Migration plan:
/// once a dedicated Cloud Function performs (or a Firestore trigger
/// observes) each sensitive write server-side, move this recording there
/// and keep this use case only as a thin, backward-compatible client
/// notifier (or remove it).
@injectable
final class RecordAuditLogUseCase {
  const RecordAuditLogUseCase(this._repository);

  final AuditLogRepository _repository;

  Future<AppResult<AuditLogEntry>> call({
    required String organizationId,
    required String actorUserId,
    required String actorName,
    required AuditAction action,
    required String entityType,
    required String entityId,
    Map<String, Object?>? previousValue,
    Map<String, Object?>? newValue,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedActorUserId = actorUserId.trim();
    final trimmedActorName = actorName.trim();
    final trimmedEntityType = entityType.trim();
    final trimmedEntityId = entityId.trim();

    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedActorUserId.isEmpty) {
      fieldErrors['actorUserId'] = 'ActorUserId is required.';
    }
    if (trimmedActorName.isEmpty) {
      fieldErrors['actorName'] = 'ActorName is required.';
    }
    if (trimmedEntityType.isEmpty) {
      fieldErrors['entityType'] = 'EntityType is required.';
    }
    if (trimmedEntityId.isEmpty) {
      fieldErrors['entityId'] = 'EntityId is required.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<AuditLogEntry>(
        ValidationFailure(
          'Invalid audit log entry payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_audit_log_entry_payload',
        ),
      );
    }

    final entry = AuditLogEntryFactory.build(
      organizationId: trimmedOrganizationId,
      actorUserId: trimmedActorUserId,
      actorName: trimmedActorName,
      action: action,
      entityType: trimmedEntityType,
      entityId: trimmedEntityId,
      previousValue: previousValue,
      newValue: newValue,
    );

    return _repository.record(entry);
  }
}
