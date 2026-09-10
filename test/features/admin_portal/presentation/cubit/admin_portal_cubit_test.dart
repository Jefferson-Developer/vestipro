import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/admin_portal/admin_portal.dart';

void main() {
  group('AdminPortalCubit', () {
    blocTest<AdminPortalCubit, AdminPortalState>(
      'denies portal when internal operator lacks view permission',
      build: () => _buildCubit(
        repository: _FakeAdminPortalRepository(
          session: const VestiProOperatorSession(
            userId: 'operator-1',
            displayName: 'Operador',
            permissions: <VestiProOperatorPermission>{},
          ),
        ),
      ),
      act: (cubit) => cubit.loadSession(),
      expect: () => <dynamic>[
        isA<AdminPortalState>().having(
          (state) => state.status,
          'status',
          AdminPortalStatus.loadingSession,
        ),
        isA<AdminPortalState>().having(
          (state) => state.status,
          'status',
          AdminPortalStatus.denied,
        ),
      ],
    );

    blocTest<AdminPortalCubit, AdminPortalState>(
      'searches organizations only after a valid support reason',
      build: () => _buildCubit(repository: _FakeAdminPortalRepository()),
      act: (cubit) async {
        await cubit.loadSession();
        cubit.updateReason('SUP-203 investigacao');
        await cubit.search('acme');
      },
      verify: (cubit) {
        expect(cubit.state.organizations.single.organizationId, 'org-1');
        expect(cubit.state.status, AdminPortalStatus.ready);
      },
    );

    blocTest<AdminPortalCubit, AdminPortalState>(
      'surfaces validation failure when reason is missing',
      build: () => _buildCubit(repository: _FakeAdminPortalRepository()),
      act: (cubit) async {
        await cubit.loadSession();
        await cubit.search('acme');
      },
      verify: (cubit) {
        expect(cubit.state.status, AdminPortalStatus.error);
        expect(cubit.state.failure, isA<ValidationFailure>());
      },
    );
  });
}

AdminPortalCubit _buildCubit({required AdminPortalRepository repository}) {
  return AdminPortalCubit(
    resolveSession: ResolveVestiProOperatorSessionUseCase(repository),
    searchOrganizations: SearchAdminOrganizationsUseCase(repository),
    loadDiagnosticReport: LoadAdminDiagnosticReportUseCase(repository),
    reprocessOutboxItem: ReprocessAdminOutboxItemUseCase(repository),
  );
}

final class _FakeAdminPortalRepository implements AdminPortalRepository {
  _FakeAdminPortalRepository({
    this.session = const VestiProOperatorSession(
      userId: 'operator-1',
      displayName: 'Operador',
      permissions: <VestiProOperatorPermission>{
        VestiProOperatorPermission.viewPortal,
        VestiProOperatorPermission.viewSensitiveData,
      },
    ),
  });

  final VestiProOperatorSession session;

  @override
  Future<AppResult<VestiProOperatorSession>> resolveOperatorSession() async {
    return AppSuccess<VestiProOperatorSession>(session);
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
          activeUsers: 8,
          syncErrors: 2,
          orderVolumeLast30Days: 42,
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
    throw UnimplementedError();
  }

  @override
  Future<AppResult<AdminPortalActionResult>> reprocessOutboxItem(
    AdminPortalAccessRequest request,
  ) async {
    throw UnimplementedError();
  }
}
