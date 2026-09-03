import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/dashboards/dashboards.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/targets/domain/repositories/positivacao_repository.dart';
import 'package:vestipro/features/targets/domain/entities/positivacao_snapshot.dart';
import 'package:vestipro/features/targets/domain/value_objects/positivacao_dimension_type.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockTeamRepository extends Mock implements TeamRepository {}

class _MockCompanyRepository extends Mock implements CompanyRepository {}

class _MockAggregationRepository extends Mock
    implements AggregationRepository {}

class _MockPositivacaoRepository extends Mock
    implements PositivacaoRepository {}

void main() {
  late _MockMembershipRepository membershipRepository;
  late _MockTeamRepository teamRepository;
  late _MockCompanyRepository companyRepository;
  late _MockAggregationRepository aggregationRepository;
  late _MockPositivacaoRepository positivacaoRepository;
  late FakeAnalyticsService analytics;

  setUpAll(() {
    registerFallbackValue(AggregationDimension.customerMonthly);
    registerFallbackValue(PositivacaoDimensionType.company);
  });

  setUp(() {
    membershipRepository = _MockMembershipRepository();
    teamRepository = _MockTeamRepository();
    companyRepository = _MockCompanyRepository();
    aggregationRepository = _MockAggregationRepository();
    positivacaoRepository = _MockPositivacaoRepository();
    analytics = FakeAnalyticsService();

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
    when(
      () => positivacaoRepository.getForDimension(
        organizationId: any(named: 'organizationId'),
        companyId: any(named: 'companyId'),
        dimensionType: any(named: 'dimensionType'),
        dimensionId: any(named: 'dimensionId'),
        periodStart: any(named: 'periodStart'),
        periodEnd: any(named: 'periodEnd'),
      ),
    ).thenAnswer(
      (invocation) async => AppSuccess<PositivacaoSnapshot>(
        PositivacaoSnapshot.notCalculated(
          organizationId: 'org-1',
          companyId: 'company-1',
          dimensionType:
              invocation.namedArguments[#dimensionType]
                  as PositivacaoDimensionType,
          dimensionId: invocation.namedArguments[#dimensionId] as String,
          periodStart: invocation.namedArguments[#periodStart] as DateTime,
          periodEnd: invocation.namedArguments[#periodEnd] as DateTime,
        ),
      ),
    );
  });

  CustomerDashboardBloc buildBloc() {
    return CustomerDashboardBloc(
      ExecutiveDashboardVisibilityService(membershipRepository, teamRepository),
      LoadCustomerDashboardSnapshotUseCase(
        aggregationRepository,
        positivacaoRepository,
      ),
      LoadCustomerDashboardRankingUseCase(aggregationRepository),
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

  AggregationSnapshot customerSnapshot(String customerId, {int index = 0}) {
    return AggregationSnapshot(
      organizationId: 'org-1',
      companyId: 'company-1',
      dimension: AggregationDimension.customerMonthly,
      scopeId: customerId,
      periodKey: '2026-08',
      revenueGross: 100.0 - index,
      revenueNet: 100.0 - index,
      discountAmount: 0,
      orderCount: 1,
      itemQuantity: 1,
      labels: <String, String>{'customerName': 'Cliente $customerId'},
      generatedAt: DateTime.utc(2026, 8, 1),
      version: 1,
    );
  }

  const filters = CustomerDashboardFilters(
    companyId: 'company-1',
    year: 2026,
    month: 8,
  );

  group('CustomerDashboardBloc', () {
    blocTest<CustomerDashboardBloc, CustomerDashboardState>(
      'a role without report.viewSensitive resolves to forbidden — same '
      'documented gap the Sales/Executive dashboards already carry',
      setUp: () {
        stubMembership('rep-1', 'SALES_REP');
        stubCompaniesAndTeams();
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const CustomerDashboardStarted(
          organizationId: 'org-1',
          userId: 'rep-1',
          initialFilters: filters,
        ),
      ),
      expect: () => <Object>[
        isA<CustomerDashboardState>().having(
          (state) => state.status,
          'status',
          CustomerDashboardStatus.loading,
        ),
        isA<CustomerDashboardState>().having(
          (state) => state.visibilityFilter?.mode,
          'visibility mode',
          ExecutiveDashboardVisibilityMode.none,
        ),
        isA<CustomerDashboardState>().having(
          (state) => state.status,
          'status',
          CustomerDashboardStatus.forbidden,
        ),
      ],
    );

    blocTest<CustomerDashboardBloc, CustomerDashboardState>(
      'an OWNER reaches ready with KPI snapshot and ranking rows, and logs '
      'dashboard_viewed(type=customer)',
      setUp: () {
        stubMembership('owner-1', 'OWNER');
        stubCompaniesAndTeams(
          companies: <Company>[companyOf('company-1', 'Marca A')],
        );
        when(
          () => aggregationRepository.listByPeriod(
            organizationId: any(named: 'organizationId'),
            dimension: AggregationDimension.customerMonthly,
            companyId: any(named: 'companyId'),
            periodKey: '2026-08',
            limit: any(named: 'limit'),
          ),
        ).thenAnswer(
          (_) async => AppSuccess<List<AggregationSnapshot>>(
            <AggregationSnapshot>[customerSnapshot('customer-a')],
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const CustomerDashboardStarted(
          organizationId: 'org-1',
          userId: 'owner-1',
          initialFilters: filters,
        ),
      ),
      verify: (bloc) {
        expect(analytics.loggedEvents, isNotEmpty);
        final event = analytics.loggedEvents.last;
        expect(event.name, AnalyticsEvents.dashboardViewed);
        expect(event.parameters?['dashboard_type'], 'customer');
        expect(event.parameters?['company_id'], 'company-1');
        expect(bloc.state.rankingStatus, CustomerDashboardRankingStatus.ready);
        expect(bloc.state.rankingRows, hasLength(1));
      },
      expect: () => <Object>[
        isA<CustomerDashboardState>(),
        isA<CustomerDashboardState>(),
        isA<CustomerDashboardState>(),
        isA<CustomerDashboardState>().having(
          (state) => state.status,
          'status',
          CustomerDashboardStatus.ready,
        ),
        isA<CustomerDashboardState>().having(
          (state) => state.rankingStatus,
          'rankingStatus',
          CustomerDashboardRankingStatus.ready,
        ),
      ],
    );

    blocTest<CustomerDashboardBloc, CustomerDashboardState>(
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
      seed: () => const CustomerDashboardState(
        status: CustomerDashboardStatus.ready,
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
        CustomerDashboardFiltersChanged(
          filters.copyWith(teamId: 'team-outsider'),
        ),
      ),
      expect: () => <Object>[],
    );

    blocTest<CustomerDashboardBloc, CustomerDashboardState>(
      'ranking pagination grows the visible window while preserving every '
      'row already loaded',
      setUp: () {
        stubMembership('owner-1', 'OWNER');
        stubCompaniesAndTeams(
          companies: <Company>[companyOf('company-1', 'Marca A')],
        );
      },
      build: buildBloc,
      seed: () => CustomerDashboardState(
        status: CustomerDashboardStatus.ready,
        organizationId: 'org-1',
        userId: 'owner-1',
        visibilityFilter: const ExecutiveDashboardVisibilityFilter(
          organizationId: 'org-1',
          userId: 'owner-1',
          mode: ExecutiveDashboardVisibilityMode.allOrganization,
        ),
        filters: filters,
        rankingStatus: CustomerDashboardRankingStatus.ready,
        rankingRows: <CustomerDashboardRankingRow>[
          for (var i = 0; i < 45; i++)
            CustomerDashboardRankingRow(
              customerId: 'customer-$i',
              customerName: 'Cliente $i',
              segment: null,
              revenueGross: 100,
              revenueNet: 100,
              orderCount: 1,
              itemQuantity: 1,
            ),
        ],
      ),
      act: (bloc) => bloc.add(const CustomerDashboardRankingPageRequested()),
      verify: (bloc) {
        expect(bloc.state.visibleRankingCount, 40);
        expect(bloc.state.visibleRankingRows, hasLength(40));
        // Every row from the first page is still present (nothing dropped).
        expect(bloc.state.visibleRankingRows.first.customerId, 'customer-0');
      },
      expect: () => <Object>[
        isA<CustomerDashboardState>().having(
          (state) => state.visibleRankingCount,
          'visibleRankingCount',
          40,
        ),
      ],
    );

    blocTest<CustomerDashboardBloc, CustomerDashboardState>(
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
        const CustomerDashboardStarted(
          organizationId: 'org-1',
          userId: 'owner-1',
          initialFilters: filters,
        ),
      ),
      expect: () => <Object>[
        isA<CustomerDashboardState>(),
        isA<CustomerDashboardState>(),
        isA<CustomerDashboardState>().having(
          (state) => state.status,
          'status',
          CustomerDashboardStatus.error,
        ),
      ],
    );
  });
}
