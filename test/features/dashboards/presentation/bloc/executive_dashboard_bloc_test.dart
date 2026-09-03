import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/dashboards/dashboards.dart';
import 'package:vestipro/features/insights/insights.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/targets/targets.dart';
import 'package:vestipro/features/users/users.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockTeamRepository extends Mock implements TeamRepository {}

class _MockCompanyRepository extends Mock implements CompanyRepository {}

class _MockAggregationRepository extends Mock
    implements AggregationRepository {}

class _MockPositivacaoRepository extends Mock
    implements PositivacaoRepository {}

class _MockTargetRepository extends Mock implements TargetRepository {}

class _MockTargetAchievementRepository extends Mock
    implements TargetAchievementRepository {}

class _MockInsightRepository extends Mock implements InsightRepository {}

void main() {
  late _MockMembershipRepository membershipRepository;
  late _MockTeamRepository teamRepository;
  late _MockCompanyRepository companyRepository;
  late _MockAggregationRepository aggregationRepository;
  late _MockPositivacaoRepository positivacaoRepository;
  late _MockTargetRepository targetRepository;
  late _MockTargetAchievementRepository targetAchievementRepository;
  late _MockInsightRepository insightRepository;
  late FakeAnalyticsService analytics;

  setUpAll(() {
    registerFallbackValue(
      const InsightVisibilityFilter(
        organizationId: 'org-1',
        userId: 'user-1',
        mode: InsightVisibilityMode.ownOnly,
      ),
    );
    registerFallbackValue(AggregationDimension.salesDaily);
    registerFallbackValue(PositivacaoDimensionType.company);
    registerFallbackValue(TargetDimensionType.company);
    registerFallbackValue(TargetMetricType.revenue);
  });

  setUp(() {
    membershipRepository = _MockMembershipRepository();
    teamRepository = _MockTeamRepository();
    companyRepository = _MockCompanyRepository();
    aggregationRepository = _MockAggregationRepository();
    positivacaoRepository = _MockPositivacaoRepository();
    targetRepository = _MockTargetRepository();
    targetAchievementRepository = _MockTargetAchievementRepository();
    insightRepository = _MockInsightRepository();
    analytics = FakeAnalyticsService();

    // Defaults so a bloc reaches "ready" without extra stubbing in most
    // tests — individual tests override whichever call they care about.
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
    when(
      () => positivacaoRepository.getForDimension(
        organizationId: any(named: 'organizationId'),
        companyId: any(named: 'companyId'),
        dimensionType: any(named: 'dimensionType'),
        dimensionId: any(named: 'dimensionId'),
        periodStart: any(named: 'periodStart'),
        periodEnd: any(named: 'periodEnd'),
      ),
    ).thenAnswer((invocation) async {
      final args = invocation.namedArguments;
      return AppSuccess<PositivacaoSnapshot>(
        PositivacaoSnapshot.notCalculated(
          organizationId: args[#organizationId] as String,
          companyId: args[#companyId] as String,
          dimensionType: args[#dimensionType] as PositivacaoDimensionType,
          dimensionId: args[#dimensionId] as String,
          periodStart: args[#periodStart] as DateTime,
          periodEnd: args[#periodEnd] as DateTime,
        ),
      );
    });
    when(
      () => targetRepository.listByDimension(
        organizationId: any(named: 'organizationId'),
        companyId: any(named: 'companyId'),
        dimensionType: any(named: 'dimensionType'),
        dimensionId: any(named: 'dimensionId'),
        metricType: any(named: 'metricType'),
      ),
    ).thenAnswer((_) async => const AppSuccess<List<Target>>(<Target>[]));
    when(
      () => insightRepository.listPageByVisibility(
        organizationId: any(named: 'organizationId'),
        visibility: any(named: 'visibility'),
        limit: any(named: 'limit'),
        before: any(named: 'before'),
        type: any(named: 'type'),
      ),
    ).thenAnswer(
      (_) async => const AppSuccess<InsightPage>(
        InsightPage(insights: <Insight>[], hasMore: false),
      ),
    );
  });

  ExecutiveDashboardBloc buildBloc() {
    return ExecutiveDashboardBloc(
      ExecutiveDashboardVisibilityService(membershipRepository, teamRepository),
      LoadExecutiveDashboardSnapshotUseCase(
        aggregationRepository,
        positivacaoRepository,
        targetRepository,
        targetAchievementRepository,
      ),
      companyRepository,
      teamRepository,
      ListOpportunityCenterInsightsUseCase(
        InsightVisibilityService(
          PortfolioVisibilityService(membershipRepository, teamRepository),
          teamRepository,
        ),
        insightRepository,
      ),
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
  }) {
    final now = DateTime.utc(2026, 1, 1);
    return Team(
      id: id,
      organizationId: 'org-1',
      name: name,
      companyId: companyId,
      managerUserId: managerUserId ?? '',
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

  const filters = ExecutiveDashboardFilters(
    companyId: 'company-1',
    year: 2026,
    month: 8,
  );

  group('ExecutiveDashboardBloc', () {
    blocTest<ExecutiveDashboardBloc, ExecutiveDashboardState>(
      'a role without report.viewSensitive resolves to forbidden',
      setUp: () {
        stubMembership('rep-1', 'SALES_REP');
        stubCompaniesAndTeams();
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const ExecutiveDashboardStarted(
          organizationId: 'org-1',
          userId: 'rep-1',
          initialFilters: filters,
        ),
      ),
      expect: () => <Object>[
        isA<ExecutiveDashboardState>().having(
          (state) => state.status,
          'status',
          ExecutiveDashboardStatus.loading,
        ),
        isA<ExecutiveDashboardState>().having(
          (state) => state.visibilityFilter?.mode,
          'visibility mode',
          ExecutiveDashboardVisibilityMode.none,
        ),
        isA<ExecutiveDashboardState>().having(
          (state) => state.status,
          'status',
          ExecutiveDashboardStatus.forbidden,
        ),
      ],
    );

    blocTest<ExecutiveDashboardBloc, ExecutiveDashboardState>(
      'an OWNER reaches ready with company options and logs dashboard_viewed',
      setUp: () {
        stubMembership('owner-1', 'OWNER');
        stubCompaniesAndTeams(
          companies: <Company>[companyOf('company-1', 'Marca A')],
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const ExecutiveDashboardStarted(
          organizationId: 'org-1',
          userId: 'owner-1',
          initialFilters: filters,
        ),
      ),
      verify: (_) {
        expect(analytics.loggedEvents, isNotEmpty);
        final event = analytics.loggedEvents.last;
        expect(event.name, AnalyticsEvents.dashboardViewed);
        expect(event.parameters?['dashboard_type'], 'executive');
        expect(event.parameters?['company_id'], 'company-1');
      },
      expect: () => <Object>[
        isA<ExecutiveDashboardState>(),
        isA<ExecutiveDashboardState>(),
        isA<ExecutiveDashboardState>(),
        isA<ExecutiveDashboardState>().having(
          (state) => state.status,
          'status',
          ExecutiveDashboardStatus.ready,
        ),
        // The top-insights shortcut load (never blocking the KPI snapshot
        // above) resolves right after and emits once more.
        isA<ExecutiveDashboardState>(),
      ],
    );

    blocTest<ExecutiveDashboardBloc, ExecutiveDashboardState>(
      'falls back to the first allowed company when the initial filters '
      "point to a company outside the caller's scope",
      setUp: () {
        stubMembership('manager-1', 'SALES_MANAGER', teamIds: ['team-a']);
        stubCompaniesAndTeams(
          companies: <Company>[companyOf('company-allowed', 'Marca Permitida')],
          teams: <Team>[
            teamOf(
              'team-a',
              'Equipe A',
              companyId: 'company-allowed',
              managerUserId: 'manager-1',
            ),
          ],
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const ExecutiveDashboardStarted(
          organizationId: 'org-1',
          userId: 'manager-1',
          initialFilters: ExecutiveDashboardFilters(
            companyId: 'company-outsider',
            year: 2026,
            month: 8,
          ),
        ),
      ),
      expect: () => <Object>[
        isA<ExecutiveDashboardState>(),
        isA<ExecutiveDashboardState>(),
        isA<ExecutiveDashboardState>().having(
          (state) => state.filters.companyId,
          'filters.companyId',
          'company-allowed',
        ),
        isA<ExecutiveDashboardState>().having(
          (state) => state.status,
          'status',
          ExecutiveDashboardStatus.ready,
        ),
        isA<ExecutiveDashboardState>(),
      ],
    );

    blocTest<ExecutiveDashboardBloc, ExecutiveDashboardState>(
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
      seed: () => const ExecutiveDashboardState(
        status: ExecutiveDashboardStatus.ready,
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
        ExecutiveDashboardFiltersChanged(
          filters.copyWith(teamId: 'team-outsider'),
        ),
      ),
      expect: () => <Object>[],
    );

    blocTest<ExecutiveDashboardBloc, ExecutiveDashboardState>(
      'a filter change reloads the snapshot for the new month',
      setUp: () {
        stubMembership('owner-1', 'OWNER');
        stubCompaniesAndTeams(
          companies: <Company>[companyOf('company-1', 'Marca A')],
        );
      },
      build: buildBloc,
      seed: () => ExecutiveDashboardState(
        status: ExecutiveDashboardStatus.ready,
        organizationId: 'org-1',
        userId: 'owner-1',
        visibilityFilter: const ExecutiveDashboardVisibilityFilter(
          organizationId: 'org-1',
          userId: 'owner-1',
          mode: ExecutiveDashboardVisibilityMode.allOrganization,
        ),
        companyOptions: const <ExecutiveDashboardScopeOption>[
          ExecutiveDashboardScopeOption(id: 'company-1', name: 'Marca A'),
        ],
        filters: filters,
        snapshot: null,
      ),
      act: (bloc) => bloc.add(
        ExecutiveDashboardFiltersChanged(filters.copyWith(month: 7)),
      ),
      expect: () => <Object>[
        isA<ExecutiveDashboardState>().having(
          (state) => state.status,
          'status',
          ExecutiveDashboardStatus.loading,
        ),
        isA<ExecutiveDashboardState>()
            .having(
              (state) => state.status,
              'status',
              ExecutiveDashboardStatus.ready,
            )
            .having((state) => state.filters.month, 'filters.month', 7),
        isA<ExecutiveDashboardState>(),
      ],
    );

    blocTest<ExecutiveDashboardBloc, ExecutiveDashboardState>(
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
        const ExecutiveDashboardStarted(
          organizationId: 'org-1',
          userId: 'owner-1',
          initialFilters: filters,
        ),
      ),
      expect: () => <Object>[
        isA<ExecutiveDashboardState>(),
        isA<ExecutiveDashboardState>(),
        isA<ExecutiveDashboardState>().having(
          (state) => state.status,
          'status',
          ExecutiveDashboardStatus.error,
        ),
      ],
    );

    blocTest<ExecutiveDashboardBloc, ExecutiveDashboardState>(
      'a retried load reloads after a snapshot failure, without re-checking '
      'visibility again',
      setUp: () {
        stubMembership('owner-1', 'OWNER');
        stubCompaniesAndTeams(
          companies: <Company>[companyOf('company-1', 'Marca A')],
        );
      },
      build: buildBloc,
      seed: () => ExecutiveDashboardState(
        status: ExecutiveDashboardStatus.error,
        organizationId: 'org-1',
        userId: 'owner-1',
        visibilityFilter: const ExecutiveDashboardVisibilityFilter(
          organizationId: 'org-1',
          userId: 'owner-1',
          mode: ExecutiveDashboardVisibilityMode.allOrganization,
        ),
        filters: filters,
        failure: const ServerFailure('boom', code: 'boom'),
      ),
      act: (bloc) => bloc.add(const ExecutiveDashboardRetried()),
      expect: () => <Object>[
        isA<ExecutiveDashboardState>().having(
          (state) => state.status,
          'status',
          ExecutiveDashboardStatus.loading,
        ),
        isA<ExecutiveDashboardState>().having(
          (state) => state.status,
          'status',
          ExecutiveDashboardStatus.ready,
        ),
        isA<ExecutiveDashboardState>(),
      ],
    );

    blocTest<ExecutiveDashboardBloc, ExecutiveDashboardState>(
      'loads the top insights of the filtered period for the Central de '
      'Oportunidades shortcut, sorted by estimated impact',
      setUp: () {
        stubMembership('owner-1', 'OWNER');
        stubCompaniesAndTeams(
          companies: <Company>[companyOf('company-1', 'Marca A')],
        );
        when(
          () => insightRepository.listPageByVisibility(
            organizationId: any(named: 'organizationId'),
            visibility: any(named: 'visibility'),
            limit: any(named: 'limit'),
            before: any(named: 'before'),
            type: any(named: 'type'),
          ),
        ).thenAnswer(
          (_) async => AppSuccess<InsightPage>(
            InsightPage(
              insights: <Insight>[
                _insight(
                  id: 'low',
                  amount: 100,
                  generatedAt: DateTime.utc(2026, 8, 5),
                ),
                _insight(
                  id: 'high',
                  amount: 900,
                  generatedAt: DateTime.utc(2026, 8, 6),
                ),
                _insight(
                  id: 'outside-period',
                  amount: 5000,
                  generatedAt: DateTime.utc(2026, 6, 1),
                ),
              ],
              hasMore: false,
            ),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const ExecutiveDashboardStarted(
          organizationId: 'org-1',
          userId: 'owner-1',
          initialFilters: filters,
        ),
      ),
      verify: (bloc) {
        expect(
          bloc.state.topInsights.map((insight) => insight.id).toList(),
          <String>['high', 'low'],
        );
      },
    );
  });
}

Insight _insight({
  required String id,
  required double amount,
  required DateTime generatedAt,
}) {
  return Insight(
    id: id,
    type: InsightType.crossSell,
    title: 'Insight $id',
    description: 'Descrição $id',
    estimatedImpact: InsightEstimatedImpact(amount: amount),
    severity: InsightSeverity.medium,
    confidenceScore: 0.8,
    recommendation: 'Recomendação',
    quickAction: const InsightAction(
      type: InsightActionType.openCustomer,
      label: 'Abrir cliente',
    ),
    organizationId: 'org-1',
    companyId: 'company-1',
    recipientUserId: 'owner-1',
    generatedAt: generatedAt,
    expiresAt: generatedAt.add(const Duration(days: 30)),
    status: InsightStatus.fresh,
  );
}
