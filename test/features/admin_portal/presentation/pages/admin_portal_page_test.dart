import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/admin_portal/admin_portal.dart';

void main() {
  testWidgets('renders search and diagnostic flow with mandatory reason', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeAdminPortalRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AdminPortalPage(
          createCubit: () => AdminPortalCubit(
            resolveSession: ResolveVestiProOperatorSessionUseCase(repository),
            searchOrganizations: SearchAdminOrganizationsUseCase(repository),
            loadDiagnosticReport: LoadAdminDiagnosticReportUseCase(repository),
            reprocessOutboxItem: ReprocessAdminOutboxItemUseCase(repository),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Portal administrativo VestiPro'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField).at(1),
      'SUP-203 sync travado',
    );
    await tester.enterText(find.byType(TextField).at(3), 'user-1');
    await tester.enterText(find.byType(TextField).at(4), 'device-1');
    await tester.enterText(find.byType(TextField).first, 'Acme');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('Acme Fashion'), findsOneWidget);
    await tester.tap(find.text('Acme Fashion'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Consultar sync'));
    await tester.pumpAndSettle();

    expect(find.text('Outbox com falha'), findsOneWidget);
    expect(find.text('Falha de sync sanitizada'), findsOneWidget);
    expect(repository.lastDiagnosticRequest?.reason, 'SUP-203 sync travado');
  });
}

final class _FakeAdminPortalRepository implements AdminPortalRepository {
  AdminPortalAccessRequest? lastDiagnosticRequest;

  @override
  Future<AppResult<VestiProOperatorSession>> resolveOperatorSession() async {
    return const AppSuccess<VestiProOperatorSession>(
      VestiProOperatorSession(
        userId: 'operator-1',
        displayName: 'Operador',
        permissions: <VestiProOperatorPermission>{
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
    return AppSuccess<List<AdminOrganizationSummary>>(
      <AdminOrganizationSummary>[
        AdminOrganizationSummary(
          organizationId: 'org-1',
          displayName: 'Acme Fashion',
          status: 'active',
          healthStatus: AdminPortalHealthStatus.warning,
          activeUsers: 10,
          syncErrors: 1,
          orderVolumeLast30Days: 12,
          openTickets: 1,
          lastActivityAt: DateTime.utc(2026, 9, 10),
        ),
      ],
    );
  }

  @override
  Future<AppResult<AdminPortalDiagnosticReport>> loadDiagnosticReport(
    AdminPortalAccessRequest request,
  ) async {
    lastDiagnosticRequest = request;
    return AppSuccess<AdminPortalDiagnosticReport>(
      AdminPortalDiagnosticReport(
        organizationId: request.organizationId,
        userId: request.targetUserId!,
        deviceId: request.deviceId!,
        syncStatus: 'failed',
        pendingOutboxItems: 2,
        failedOutboxItems: 1,
        lastSyncAt: DateTime.utc(2026, 9, 10),
        technicalLogs: <AdminPortalTechnicalLog>[
          AdminPortalTechnicalLog(
            id: 'log-1',
            level: AdminPortalLogLevel.error,
            message: 'Falha de sync sanitizada',
            occurredAt: DateTime.utc(2026, 9, 10),
            correlationId: 'corr-1',
          ),
        ],
      ),
    );
  }

  @override
  Future<AppResult<AdminPortalActionResult>> reprocessOutboxItem(
    AdminPortalAccessRequest request,
  ) async {
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
