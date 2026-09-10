import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/admin_portal/admin_portal.dart';

void main() {
  group('Admin portal use cases', () {
    test('requires a support reason before organization search', () async {
      final repository = _FakeAdminPortalRepository();
      final useCase = SearchAdminOrganizationsUseCase(repository);

      final result = await useCase(query: 'acme', reason: 'curto');

      expect(result, isA<AppFailure<List<AdminOrganizationSummary>>>());
      expect(
        (result as AppFailure<List<AdminOrganizationSummary>>).failure,
        isA<ValidationFailure>(),
      );
      expect(repository.searchCalls, 0);
    });

    test('normalizes diagnostic scope before repository call', () async {
      final repository = _FakeAdminPortalRepository();
      final useCase = LoadAdminDiagnosticReportUseCase(repository);

      final result = await useCase(
        const AdminPortalAccessRequest(
          organizationId: ' org-1 ',
          reason: ' SUP-42 sync travado ',
          kind: AdminPortalAccessKind.sensitiveDetail,
          targetUserId: ' user-1 ',
          deviceId: ' device-1 ',
        ),
      );

      expect(result, isA<AppSuccess<AdminPortalDiagnosticReport>>());
      expect(repository.lastRequest?.organizationId, 'org-1');
      expect(repository.lastRequest?.reason, 'SUP-42 sync travado');
      expect(repository.lastRequest?.targetUserId, 'user-1');
      expect(repository.lastRequest?.deviceId, 'device-1');
    });

    test('requires outbox item id for reprocessing', () async {
      final repository = _FakeAdminPortalRepository();
      final useCase = ReprocessAdminOutboxItemUseCase(repository);

      final result = await useCase(
        const AdminPortalAccessRequest(
          organizationId: 'org-1',
          reason: 'SUP-42 retry solicitado',
          kind: AdminPortalAccessKind.supportAction,
        ),
      );

      expect(result, isA<AppFailure<AdminPortalActionResult>>());
      expect(repository.reprocessCalls, 0);
    });
  });
}

final class _FakeAdminPortalRepository implements AdminPortalRepository {
  int searchCalls = 0;
  int reprocessCalls = 0;
  AdminPortalAccessRequest? lastRequest;

  @override
  Future<AppResult<VestiProOperatorSession>> resolveOperatorSession() async {
    return const AppSuccess<VestiProOperatorSession>(
      VestiProOperatorSession(
        userId: 'operator-1',
        displayName: 'Operador',
        permissions: {
          VestiProOperatorPermission.viewPortal,
          VestiProOperatorPermission.viewSensitiveData,
          VestiProOperatorPermission.reprocessOutbox,
        },
      ),
    );
  }

  @override
  Future<AppResult<List<AdminOrganizationSummary>>> searchOrganizations({
    required String query,
    required String reason,
    String? ticketId,
  }) async {
    searchCalls++;
    return const AppSuccess<List<AdminOrganizationSummary>>(
      <AdminOrganizationSummary>[],
    );
  }

  @override
  Future<AppResult<AdminPortalDiagnosticReport>> loadDiagnosticReport(
    AdminPortalAccessRequest request,
  ) async {
    lastRequest = request;
    return AppSuccess<AdminPortalDiagnosticReport>(
      AdminPortalDiagnosticReport(
        organizationId: request.organizationId,
        userId: request.targetUserId!,
        deviceId: request.deviceId!,
        syncStatus: 'failed',
        pendingOutboxItems: 1,
        failedOutboxItems: 1,
        lastSyncAt: DateTime.utc(2026, 9, 10),
        technicalLogs: const <AdminPortalTechnicalLog>[],
      ),
    );
  }

  @override
  Future<AppResult<AdminPortalActionResult>> reprocessOutboxItem(
    AdminPortalAccessRequest request,
  ) async {
    reprocessCalls++;
    return const AppSuccess<AdminPortalActionResult>(
      AdminPortalActionResult(
        organizationId: 'org-1',
        action: 'vestiproAdmin.outboxReprocessRequested',
        message: 'ok',
        auditLogId: 'audit-1',
      ),
    );
  }
}
