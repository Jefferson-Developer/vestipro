import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/reports/reports.dart';

void main() {
  const organizationId = 'org-a';
  const companyId = 'company-a';
  const userId = 'rep-a';

  final definition = ReportDefinition(
    organizationId: organizationId,
    companyId: companyId,
    dimensions: const <String>['seller'],
    metrics: const <String>['revenueGross'],
  );

  SavedReport buildReport({
    String id = 'report-1',
    String ownerId = userId,
    SavedReportVisibility visibility = SavedReportVisibility.private,
  }) => SavedReport(
    id: id,
    organizationId: organizationId,
    companyId: companyId,
    ownerId: ownerId,
    name: 'Minhas vendas',
    definition: definition,
    visibility: visibility,
    favorite: false,
    createdAt: DateTime.utc(2026, 1, 1),
    createdBy: ownerId,
    updatedAt: DateTime.utc(2026, 1, 1),
    updatedBy: ownerId,
  );

  late _FakeSavedReportRepository repository;
  late _FakeMembershipRepository membershipRepository;
  late _FakeScheduleReferenceChecker scheduleReferenceChecker;
  late _FakeDraftRepository drafts;
  late FakeAnalyticsService analytics;

  SavedReportsBloc buildBloc() {
    final permissionService = PermissionService(membershipRepository);
    return SavedReportsBloc(
      ListSavedReports(repository, membershipRepository),
      SaveReportView(repository, membershipRepository, permissionService),
      UpdateSavedReport(repository, membershipRepository, permissionService),
      DeleteSavedReport(
        repository,
        membershipRepository,
        scheduleReferenceChecker,
      ),
      OpenSavedReportInBuilder(drafts),
      analytics,
    );
  }

  setUp(() {
    repository = _FakeSavedReportRepository();
    membershipRepository = _FakeMembershipRepository();
    scheduleReferenceChecker = _FakeScheduleReferenceChecker();
    drafts = _FakeDraftRepository();
    analytics = FakeAnalyticsService();
    membershipRepository.membership = Membership(
      id: userId,
      organizationId: organizationId,
      userId: userId,
      roleId: 'SALES_REP',
      roleName: 'SALES_REP',
      teamIds: const <String>['team-a'],
      status: MembershipStatus.active,
      version: 1,
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: userId,
      updatedAt: DateTime.utc(2026, 1, 1),
      updatedBy: userId,
    );
  });

  blocTest<SavedReportsBloc, SavedReportsState>(
    'loads owned and shared reports on start',
    build: buildBloc,
    act: (bloc) {
      repository.owned = <SavedReport>[buildReport(id: 'owned-1')];
      repository.shared = <SavedReport>[
        buildReport(
          id: 'shared-1',
          ownerId: 'manager-a',
          visibility: SavedReportVisibility.organization,
        ),
      ];
      bloc.add(
        const SavedReportsStarted(
          organizationId: organizationId,
          companyId: companyId,
          userId: userId,
        ),
      );
    },
    expect: () => [
      predicate<SavedReportsState>(
        (s) => s.status == SavedReportsStatus.loading,
      ),
      predicate<SavedReportsState>(
        (s) =>
            s.status == SavedReportsStatus.ready &&
            s.owned.length == 1 &&
            s.shared.length == 1 &&
            !s.isEmpty,
      ),
    ],
  );

  blocTest<SavedReportsBloc, SavedReportsState>(
    'surfaces an empty state when there is nothing owned nor shared',
    build: buildBloc,
    act: (bloc) => bloc.add(
      const SavedReportsStarted(
        organizationId: organizationId,
        companyId: companyId,
        userId: userId,
      ),
    ),
    expect: () => [
      predicate<SavedReportsState>(
        (s) => s.status == SavedReportsStatus.loading,
      ),
      predicate<SavedReportsState>(
        (s) => s.status == SavedReportsStatus.ready && s.isEmpty,
      ),
    ],
  );

  blocTest<SavedReportsBloc, SavedReportsState>(
    'surfaces a network/repository failure without crashing',
    build: buildBloc,
    act: (bloc) {
      repository.ownedFailure = const ConnectivityFailure('Sem conexão.');
      bloc.add(
        const SavedReportsStarted(
          organizationId: organizationId,
          companyId: companyId,
          userId: userId,
        ),
      );
    },
    expect: () => [
      predicate<SavedReportsState>(
        (s) => s.status == SavedReportsStatus.loading,
      ),
      predicate<SavedReportsState>(
        (s) =>
            s.status == SavedReportsStatus.failure &&
            s.failure is ConnectivityFailure,
      ),
    ],
  );

  blocTest<SavedReportsBloc, SavedReportsState>(
    'creating a new saved view logs report_view_saved and appends it to owned',
    build: buildBloc,
    act: (bloc) async {
      bloc.add(
        const SavedReportsStarted(
          organizationId: organizationId,
          companyId: companyId,
          userId: userId,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      bloc.add(
        SavedReportCreateRequested(
          name: 'Vendas do mês',
          definition: definition,
        ),
      );
    },
    wait: const Duration(milliseconds: 10),
    verify: (bloc) {
      expect(bloc.state.owned, hasLength(1));
      expect(bloc.state.owned.single.name, 'Vendas do mês');
      expect(
        analytics.loggedEvents.map((e) => e.name),
        contains(AnalyticsEvents.reportViewSaved),
      );
    },
  );

  blocTest<SavedReportsBloc, SavedReportsState>(
    'deleting a report blocked by an active schedule surfaces the failure and '
    'never removes it from the list (no silent delete)',
    build: buildBloc,
    act: (bloc) async {
      final report = buildReport(id: 'owned-1');
      repository.owned = <SavedReport>[report];
      scheduleReferenceChecker.blockedReportIds.add(report.id);
      bloc.add(
        const SavedReportsStarted(
          organizationId: organizationId,
          companyId: companyId,
          userId: userId,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      bloc.add(SavedReportDeleteRequested(report));
    },
    wait: const Duration(milliseconds: 10),
    verify: (bloc) {
      expect(bloc.state.owned, hasLength(1));
      expect(bloc.state.failure, isA<ConflictFailure>());
    },
  );
}

final class _FakeSavedReportRepository implements SavedReportRepository {
  List<SavedReport> owned = <SavedReport>[];
  List<SavedReport> shared = <SavedReport>[];
  Failure? ownedFailure;

  @override
  Future<AppResult<List<SavedReport>>> listOwned({
    required String organizationId,
    required String companyId,
    required String userId,
  }) async {
    if (ownedFailure != null) {
      return AppFailure<List<SavedReport>>(ownedFailure!);
    }
    return AppSuccess<List<SavedReport>>(
      owned.where((r) => r.ownerId == userId).toList(growable: false),
    );
  }

  @override
  Future<AppResult<List<SavedReport>>> listSharedWithMe({
    required String organizationId,
    required String companyId,
    required String userId,
    required List<String> teamIds,
  }) async => AppSuccess<List<SavedReport>>(shared);

  @override
  Future<AppResult<SavedReport>> create(SavedReport report) async {
    owned = <SavedReport>[...owned, report];
    return AppSuccess<SavedReport>(report);
  }

  @override
  Future<AppResult<SavedReport>> update(SavedReport report) async {
    owned = owned
        .map((r) => r.id == report.id ? report : r)
        .toList(growable: false);
    return AppSuccess<SavedReport>(report);
  }

  @override
  Future<AppResult<void>> delete({
    required String organizationId,
    required String reportId,
  }) async {
    owned = owned.where((r) => r.id != reportId).toList(growable: false);
    return const AppSuccess<void>(null);
  }
}

final class _FakeMembershipRepository implements MembershipRepository {
  Membership? membership;

  @override
  Future<AppResult<Membership>> getByUser({
    required String organizationId,
    required String userId,
  }) async {
    final current = membership;
    if (current == null) {
      return const AppFailure<Membership>(NotFoundFailure('Not found.'));
    }
    return AppSuccess<Membership>(current);
  }

  @override
  Future<AppResult<Membership>> create({
    required String organizationId,
    required String userId,
    required String roleId,
    required String roleName,
    List<String> teamIds = const <String>[],
    required String createdBy,
  }) async => throw UnimplementedError();

  @override
  Future<AppResult<List<Membership>>> listByOrganization(
    String organizationId,
  ) async => throw UnimplementedError();

  @override
  Future<AppResult<Membership>> update({
    required String organizationId,
    required String userId,
    required String roleId,
    required String roleName,
    required List<String> teamIds,
    required MembershipStatus status,
    required String updatedBy,
  }) async => throw UnimplementedError();

  @override
  Future<AppResult<List<Membership>>> listActiveByUser(String userId) async =>
      throw UnimplementedError();
}

final class _FakeScheduleReferenceChecker
    implements ReportScheduleReferenceChecker {
  final Set<String> blockedReportIds = <String>{};

  @override
  Future<AppResult<bool>> hasActiveScheduleReferencing(
    String savedReportId,
  ) async => AppSuccess<bool>(blockedReportIds.contains(savedReportId));
}

final class _FakeDraftRepository implements ReportDraftRepository {
  @override
  Future<ReportDefinition?> load({
    required String userId,
    required String organizationId,
    required String companyId,
  }) async => null;

  @override
  Future<void> save({
    required String userId,
    required ReportDefinition definition,
  }) async {}
}
