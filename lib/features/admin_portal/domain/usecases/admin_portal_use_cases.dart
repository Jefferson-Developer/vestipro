import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/admin_portal_models.dart';
import '../repositories/admin_portal_repository.dart';

const int adminPortalMinimumReasonLength = 8;

final class ResolveVestiProOperatorSessionUseCase {
  const ResolveVestiProOperatorSessionUseCase(this._repository);

  final AdminPortalRepository _repository;

  Future<AppResult<VestiProOperatorSession>> call() {
    return _repository.resolveOperatorSession();
  }
}

final class SearchAdminOrganizationsUseCase {
  const SearchAdminOrganizationsUseCase(this._repository);

  final AdminPortalRepository _repository;

  Future<AppResult<List<AdminOrganizationSummary>>> call({
    required String query,
    required String reason,
    String? ticketId,
  }) {
    final validation = validateSupportReason(reason);
    if (validation != null) {
      return Future.value(
        AppFailure<List<AdminOrganizationSummary>>(validation),
      );
    }
    return _repository.searchOrganizations(
      query: query,
      reason: reason.trim(),
      ticketId: _normalizeOptional(ticketId),
    );
  }
}

final class LoadAdminDiagnosticReportUseCase {
  const LoadAdminDiagnosticReportUseCase(this._repository);

  final AdminPortalRepository _repository;

  Future<AppResult<AdminPortalDiagnosticReport>> call(
    AdminPortalAccessRequest request,
  ) {
    final normalized = normalizeAccessRequest(request);
    final validation = validateSupportReason(normalized.reason);
    if (validation != null) {
      return Future.value(AppFailure<AdminPortalDiagnosticReport>(validation));
    }
    if (normalized.targetUserId == null || normalized.deviceId == null) {
      return Future.value(
        const AppFailure<AdminPortalDiagnosticReport>(
          ValidationFailure(
            'Informe usuario e dispositivo para consultar o diagnostico.',
            code: 'admin_portal.missing_diagnostic_scope',
          ),
        ),
      );
    }
    return _repository.loadDiagnosticReport(normalized);
  }
}

final class ReprocessAdminOutboxItemUseCase {
  const ReprocessAdminOutboxItemUseCase(this._repository);

  final AdminPortalRepository _repository;

  Future<AppResult<AdminPortalActionResult>> call(
    AdminPortalAccessRequest request,
  ) {
    final normalized = normalizeAccessRequest(request);
    final validation = validateSupportReason(normalized.reason);
    if (validation != null) {
      return Future.value(AppFailure<AdminPortalActionResult>(validation));
    }
    if (normalized.outboxItemId == null) {
      return Future.value(
        const AppFailure<AdminPortalActionResult>(
          ValidationFailure(
            'Informe o item da Outbox para reprocessar.',
            code: 'admin_portal.missing_outbox_item',
          ),
        ),
      );
    }
    return _repository.reprocessOutboxItem(normalized);
  }
}

Failure? validateSupportReason(String reason) {
  if (reason.trim().length < adminPortalMinimumReasonLength) {
    return const ValidationFailure(
      'Informe uma justificativa de suporte antes de acessar dados da organizacao.',
      code: 'admin_portal.reason_required',
    );
  }
  return null;
}

AdminPortalAccessRequest normalizeAccessRequest(
  AdminPortalAccessRequest request,
) {
  return AdminPortalAccessRequest(
    organizationId: request.organizationId.trim(),
    reason: request.reason.trim(),
    kind: request.kind,
    ticketId: _normalizeOptional(request.ticketId),
    targetUserId: _normalizeOptional(request.targetUserId),
    deviceId: _normalizeOptional(request.deviceId),
    outboxItemId: _normalizeOptional(request.outboxItemId),
  );
}

String? _normalizeOptional(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
