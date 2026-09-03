import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/dashboards/dashboards.dart';
import 'package:vestipro/features/insights/insights.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/targets/targets.dart';
import 'package:vestipro/features/users/users.dart';

import '../../../../core/design_system/components/test_pump_app.dart';

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
  late PermissionService permissionService;

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
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
    permissionService = PermissionService(membershipRepository);

    when(() => companyRepository.listByOrganization('org-1')).thenAnswer(
      (_) async => AppSuccess<List<Company>>(<Company>[
        Company(
          id: 'company-1',
          organizationId: 'org-1',
          name: 'Marca A',
          status: CompanyStatus.active,
          version: 1,
          createdAt: DateTime.utc(2026, 1, 1),
          createdBy: 'owner-1',
          updatedAt: DateTime.utc(2026, 1, 1),
          updatedBy: 'owner-1',
        ),
      ]),
    );
    when(
      () => teamRepository.listByOrganization('org-1'),
    ).thenAnswer((_) async => const AppSuccess<List<Team>>(<Team>[]));
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
      (_) async => AppSuccess<List<AggregationSnapshot>>(<AggregationSnapshot>[
        AggregationSnapshot(
          organizationId: 'org-1',
          companyId: 'company-1',
          dimension: AggregationDimension.salesDaily,
          scopeId: 'company-1',
          periodKey: '2026-08-01',
          revenueGross: 1000,
          revenueNet: 1000,
          discountAmount: 0,
          orderCount: 2,
          itemQuantity: 2,
          labels: const <String, String>{},
          generatedAt: DateTime.utc(2026, 8, 1),
          version: 1,
        ),
      ]),
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

  void stubMembership(String userId, String roleName) {
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

  void setWidth(WidgetTester tester, double width) {
    final view = tester.view;
    view.physicalSize = Size(width, 1400);
    view.devicePixelRatio = 1.0;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);
  }

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
      FakeAnalyticsService(),
    );
  }

  Widget buildPage({
    String userId = 'owner-1',
    VoidCallback? onOpenOpportunityCenter,
  }) {
    return ExecutiveDashboardPage(
      organizationId: 'org-1',
      userId: userId,
      permissionService: permissionService,
      createBloc: buildBloc,
      initialFilters: const ExecutiveDashboardFilters(
        companyId: 'company-1',
        year: 2026,
        month: 8,
      ),
      onOpenOpportunityCenter: onOpenOpportunityCenter ?? () {},
    );
  }

  testWidgets('shows a loading indicator before the snapshot resolves', (
    tester,
  ) async {
    stubMembership('owner-1', 'OWNER');

    await pumpApp(tester, buildPage());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets(
    'a SALES_REP (no report.viewSensitive) never reaches the dashboard — '
    'the capability gate blocks the page itself',
    (tester) async {
      stubMembership('rep-1', 'SALES_REP');

      await pumpApp(tester, buildPage(userId: 'rep-1'));
      await tester.pumpAndSettle();

      expect(
        find.text('Você não tem permissão para acessar esta página.'),
        findsOneWidget,
      );
      expect(find.text('Faturamento'), findsNothing);
    },
  );

  testWidgets('an OWNER sees every KPI card once the dashboard is ready', (
    tester,
  ) async {
    stubMembership('owner-1', 'OWNER');

    await pumpApp(tester, buildPage());
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppKpiCard, 'Faturamento'), findsOneWidget);
    expect(find.widgetWithText(AppKpiCard, 'Pedidos'), findsOneWidget);
    expect(find.widgetWithText(AppKpiCard, 'Ticket médio'), findsOneWidget);
    expect(find.widgetWithText(AppKpiCard, 'Clientes ativos'), findsOneWidget);
    expect(find.widgetWithText(AppKpiCard, 'Clientes novos'), findsOneWidget);
    expect(
      find.widgetWithText(AppKpiCard, 'Positivação de carteira'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(AppKpiCard, 'Atingimento de meta'),
      findsOneWidget,
    );
    expect(find.widgetWithText(AppKpiCard, 'Crescimento MoM'), findsOneWidget);
    expect(find.widgetWithText(AppKpiCard, 'Crescimento YoY'), findsOneWidget);
  });

  testWidgets(
    'clientes novos is shown as not-calculated, never a fabricated zero',
    (tester) async {
      stubMembership('owner-1', 'OWNER');

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.widgetWithText(AppKpiCard, 'Clientes novos'),
          matching: find.textContaining('Cálculo ainda não disponível'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('the shortcut button opens the Central de Oportunidades', (
    tester,
  ) async {
    stubMembership('owner-1', 'OWNER');
    var opened = false;

    await pumpApp(
      tester,
      buildPage(onOpenOpportunityCenter: () => opened = true),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Ver oportunidades'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver oportunidades'));
    await tester.pump();

    expect(opened, isTrue);
  });

  testWidgets('the revenue trend chart carries an accessible textual summary', (
    tester,
  ) async {
    stubMembership('owner-1', 'OWNER');

    await pumpApp(tester, buildPage());
    await tester.pumpAndSettle();

    final semantics = tester.getSemantics(find.byType(AppManagementChart));
    expect(semantics.label, contains('Gráfico de linha'));
  });

  group('responsive KPI layout', () {
    testWidgets('mobile viewport stacks the KPI cards vertically', (
      tester,
    ) async {
      stubMembership('owner-1', 'OWNER');
      setWidth(tester, 390);

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      final revenueTop = tester.getTopLeft(
        find.widgetWithText(AppKpiCard, 'Faturamento'),
      );
      final ordersTop = tester.getTopLeft(
        find.widgetWithText(AppKpiCard, 'Pedidos'),
      );

      expect(revenueTop.dy, isNot(equals(ordersTop.dy)));
    });

    testWidgets('desktop viewport lays the KPI cards side by side', (
      tester,
    ) async {
      stubMembership('owner-1', 'OWNER');
      setWidth(tester, 1600);

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      final revenueTop = tester.getTopLeft(
        find.widgetWithText(AppKpiCard, 'Faturamento'),
      );
      final ordersTop = tester.getTopLeft(
        find.widgetWithText(AppKpiCard, 'Pedidos'),
      );

      expect(revenueTop.dy, equals(ordersTop.dy));
    });

    testWidgets('tablet viewport renders every KPI card without overflow', (
      tester,
    ) async {
      stubMembership('owner-1', 'OWNER');
      setWidth(tester, 800);

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.widgetWithText(AppKpiCard, 'Faturamento'), findsOneWidget);
    });
  });
}
