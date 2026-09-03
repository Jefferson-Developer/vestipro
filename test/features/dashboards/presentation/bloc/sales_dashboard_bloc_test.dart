import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/dashboards/dashboards.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockTeamRepository extends Mock implements TeamRepository {}

class _MockCompanyRepository extends Mock implements CompanyRepository {}

class _MockAggregationRepository extends Mock
    implements AggregationRepository {}

void main() {
  late _MockMembershipRepository membershipRepository;
  late _MockTeamRepository teamRepository;
  late _MockCompanyRepository companyRepository;
  late _MockAggregationRepository aggregationRepository;
  late FakeAnalyticsService analytics;

  setUpAll(() {
    registerFallbackValue(AggregationDimension.salesDaily);
  });

  setUp(() {
    membershipRepository = _MockMembershipRepository();
    teamRepository = _MockTeamRepository();
    companyRepository = _MockCompanyRepository();
    aggregationRepository = _MockAggregationRepository();
    analytics = FakeAnalyticsService();

    when(
      () => aggregationRepository.listByPeriodRange(
        organizationId: any(named: 'organizationId'),
        dimension: any(named: 'dimension'),
        companyId: any(named: 'companyId'),
        scopeId: any(named: 'scopeId'),
        fromPeriodKey: any(named: 'fromPeriodKey'),
        toPeriodKey: any(named: 'toPeriodKey'),
      ),
    ).thenAnswer(
      (_) async =>
          const AppSuccess<List<AggregationSnapshot>>(<AggregationSnapshot>[]),
    );
    when(
      () => aggregationRepository.listByPeriod(
        organizationId: any(named: 'organizationId'),
        dimension: any(named: 'dimension'),
        companyId: any(named: 'companyId'),
        periodKey: any(named: 'periodKey'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async =>
          const AppSuccess<List<AggregationSnapshot>>(<AggregationSnapshot>[]),
    );
  });

  SalesDashboardBloc buildBloc() {
    return SalesDashboardBloc(
      ExecutiveDashboardVisibilityService(membershipRepository, teamRepository),
      LoadSalesDashboardSnapshotUseCase(aggregationRepository),
      LoadSalesDashboardGroupRowsUseCase(aggregationRepository),
      companyRepository,
      teamRepository,
      analytics,
    );
  }

  void stubMembership(
    String userId,
    String roleName, {
    List<String> teamIds = const <String>[],
  }) {
    when(
      () => membershipRepository.getByUser(
        organizationId: 'org-1',
        userId: userId,
      ),
    ).thenAnswer(
      (_) async => AppSuccess<Membership>(
        Membership(
          id: userId,
          organizationId: 'org-1',
          userId: userId,
          roleId: roleName,
          roleName: roleName,
          teamIds: teamIds,
          status: MembershipStatus.active,
          version: 1,
          createdAt: DateTime.utc(2026, 1, 1),
          createdBy: 'owner-1',
          updatedAt: DateTime.utc(2026, 1, 1),
          updatedBy: 'owner-1',
        ),
      ),
    );
  }

  Company companyOf(String id, String name) {
    final now = DateTime.utc(2026, 1, 1);
    return Company(
      id: id,
      organizationId: 'org-1',
      name: name,
      status: CompanyStatus.active,
      version: 1,
      createdAt: now,
      createdBy: 'owner-1',
      updatedAt: now,
      updatedBy: 'owner-1',
    );
  }

  Team teamOf(
    String id,
    String name, {
    String? companyId,
    String? managerUserId,
    List<String> memberIds = const <String>[],
  }) {
    final now = DateTime.utc(2026, 1, 1);
    return Team(
      id: id,
      organizationId: 'org-1',
      name: name,
      companyId: companyId,
      managerUserId: managerUserId ?? '',
      memberIds: memberIds,
      version: 1,
      createdAt: now,
      createdBy: 'owner-1',
      updatedAt: now,
      updatedBy: 'owner-1',
    );
  }

  void stubCompaniesAndTeams({
    List<Company> companies = const <Company>[],
    List<Team> teams = const <Team>[],
  }) {
    when(
      () => companyRepository.listByOrganization('org-1'),
    ).thenAnswer((_) async => AppSuccess<List<Company>>(companies));
    when(
      () => teamRepository.listByOrganization('org-1'),
    ).thenAnswer((_) async => AppSuccess<List<Team>>(teams));
  }

  const filters = SalesDashboardFilters(
    companyId: 'company-1',
    year: 2026,
    month: 8,
  );

  group('SalesDashboardBloc', () {
    blocTest<SalesDashboardBloc, SalesDashboardState>(
      'a role without report.viewSensitive resolves to forbidden — same '
      'documented gap as SALES_REP not reaching this dashboard yet',
      setUp: () {
        stubMembership('rep-1', 'SALES_REP');
        stubCompaniesAndTeams();
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const SalesDashboardStarted(
          organizationId: 'org-1',
          userId: 'rep-1',
          initialFilters: filters,
        ),
      ),
      expect: () => <Object>[
        isA<SalesDashboardState>().having(
          (state) => state.status,
          'status',
          SalesDashboardStatus.loading,
        ),
        isA<SalesDashboardState>().having(
          (state) => state.visibilityFilter?.mode,
          'visibility mode',
          ExecutiveDashboardVisibilityMode.none,
        ),
        isA<SalesDashboardState>().having(
          (state) => state.status,
          'status',
          SalesDashboardStatus.forbidden,
        ),
      ],
    );

    blocTest<SalesDashboardBloc, SalesDashboardState>(
      'an OWNER reaches ready with KPI snapshot and group rows, and logs '
      'dashboard_viewed(type=sales)',
      setUp: () {
        stubMembership('owner-1', 'OWNER');
        stubCompaniesAndTeams(
          companies: <Company>[companyOf('company-1', 'Marca A')],
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const SalesDashboardStarted(
          organizationId: 'org-1',
          userId: 'owner-1',
          initialFilters: filters,
        ),
      ),
      verify: (bloc) {
        expect(analytics.loggedEvents, isNotEmpty);
        final event = analytics.loggedEvents.last;
        expect(event.name, AnalyticsEvents.dashboardViewed);
        expect(event.parameters?['dashboard_type'], 'sales');
        expect(event.parameters?['company_id'], 'company-1');
        expect(bloc.state.groupRowsStatus, SalesDashboardGroupRowsStatus.ready);
      },
      expect: () => <Object>[
        isA<SalesDashboardState>(),
        isA<SalesDashboardState>(),
        isA<SalesDashboardState>(),
        isA<SalesDashboardState>().having(
          (state) => state.status,
          'status',
          SalesDashboardStatus.ready,
        ),
        // Group rows resolve right after the KPI snapshot, independently.
        isA<SalesDashboardState>().having(
          (state) => state.groupRowsStatus,
          'groupRowsStatus',
          SalesDashboardGroupRowsStatus.ready,
        ),
      ],
    );

    blocTest<SalesDashboardBloc, SalesDashboardState>(
      'ignores a filter change to a team outside the ownScope caller',
      setUp: () {
        stubMembership('manager-1', 'SALES_MANAGER', teamIds: ['team-a']);
        stubCompaniesAndTeams(
          companies: <Company>[companyOf('company-1', 'Marca A')],
          teams: <Team>[
            teamOf(
              'team-a',
              'Equipe A',
              companyId: 'company-1',
              managerUserId: 'manager-1',
            ),
          ],
        );
      },
      build: buildBloc,
      seed: () => const SalesDashboardState(
        status: SalesDashboardStatus.ready,
        organizationId: 'org-1',
        userId: 'manager-1',
        visibilityFilter: ExecutiveDashboardVisibilityFilter(
          organizationId: 'org-1',
          userId: 'manager-1',
          mode: ExecutiveDashboardVisibilityMode.ownScope,
          allowedCompanyIds: <String>{'company-1'},
          allowedTeamIds: <String>{'team-a'},
        ),
        filters: filters,
      ),
      act: (bloc) => bloc.add(
        SalesDashboardFiltersChanged(filters.copyWith(teamId: 'team-outsider')),
      ),
      expect: () => <Object>[],
    );

    blocTest<SalesDashboardBloc, SalesDashboardState>(
      'a SALES_MANAGER\'s "por vendedor" table is restricted to their own '
      'managed teams even with no explicit team filter applied',
      setUp: () {
        stubMembership('manager-1', 'SALES_MANAGER', teamIds: ['team-a']);
        stubCompaniesAndTeams(
          companies: <Company>[companyOf('company-1', 'Marca A')],
          teams: <Team>[
            teamOf(
              'team-a',
              'Equipe A',
              companyId: 'company-1',
              managerUserId: 'manager-1',
              memberIds: <String>['seller-managed'],
            ),
          ],
        );
        when(
          () => aggregationRepository.listByPeriod(
            organizationId: any(named: 'organizationId'),
            dimension: AggregationDimension.sellerMonthly,
            companyId: any(named: 'companyId'),
            periodKey: any(named: 'periodKey'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer(
          (_) async =>
              AppSuccess<List<AggregationSnapshot>>(<AggregationSnapshot>[
                AggregationSnapshot(
                  organizationId: 'org-1',
                  companyId: 'company-1',
                  dimension: AggregationDimension.sellerMonthly,
                  scopeId: 'seller-managed',
                  periodKey: '2026-08',
                  revenueGross: 100,
                  revenueNet: 100,
                  discountAmount: 0,
                  orderCount: 1,
                  itemQuantity: 1,
                  labels: <String, String>{},
                  generatedAt: DateTime.utc(2026, 8, 1),
                  version: 1,
                ),
              ]),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const SalesDashboardStarted(
          organizationId: 'org-1',
          userId: 'manager-1',
          initialFilters: filters,
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.groupRows.map((row) => row.scopeId), <String>[
          'seller-managed',
        ]);
      },
    );

    blocTest<SalesDashboardBloc, SalesDashboardState>(
      'a failure resolving companies surfaces the error state',
      setUp: () {
        stubMembership('owner-1', 'OWNER');
        when(() => companyRepository.listByOrganization('org-1')).thenAnswer(
          (_) async => const AppFailure<List<Company>>(
            ServerFailure('boom', code: 'boom'),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const SalesDashboardStarted(
          organizationId: 'org-1',
          userId: 'owner-1',
          initialFilters: filters,
        ),
      ),
      expect: () => <Object>[
        isA<SalesDashboardState>(),
        isA<SalesDashboardState>(),
        isA<SalesDashboardState>().having(
          (state) => state.status,
          'status',
          SalesDashboardStatus.error,
        ),
      ],
    );

    blocTest<SalesDashboardBloc, SalesDashboardState>(
      'a retried load reloads after a snapshot failure',
      setUp: () {
        stubMembership('owner-1', 'OWNER');
        stubCompaniesAndTeams(
          companies: <Company>[companyOf('company-1', 'Marca A')],
        );
      },
      build: buildBloc,
      seed: () => const SalesDashboardState(
        status: SalesDashboardStatus.error,
        organizationId: 'org-1',
        userId: 'owner-1',
        visibilityFilter: ExecutiveDashboardVisibilityFilter(
          organizationId: 'org-1',
          userId: 'owner-1',
          mode: ExecutiveDashboardVisibilityMode.allOrganization,
        ),
        filters: filters,
        failure: ServerFailure('boom', code: 'boom'),
      ),
      act: (bloc) => bloc.add(const SalesDashboardRetried()),
      expect: () => <Object>[
        isA<SalesDashboardState>().having(
          (state) => state.status,
          'status',
          SalesDashboardStatus.loading,
        ),
        isA<SalesDashboardState>().having(
          (state) => state.status,
          'status',
          SalesDashboardStatus.ready,
        ),
        isA<SalesDashboardState>(),
      ],
    );
  });
}
