import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/crm/crm.dart';
import 'package:vestipro/features/daily_rep_summary/daily_rep_summary.dart';
import 'package:vestipro/features/dashboards/dashboards.dart';
import 'package:vestipro/features/nps/nps.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/wallet_summary/wallet_summary.dart';

import '../../../../core/design_system/components/test_pump_app.dart';

class _LoadDashboard extends Mock
    implements LoadRepresentativeDashboardUseCase {}

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockTeamRepository extends Mock implements TeamRepository {}

/// Like `DailyRepSummaryCard`, `NpsScoreCard` also auto-loads on creation
/// (TASK-202 — the aggregate is already pre-computed server-side, no
/// "Gerar" gate exists), so this fake really is called by every test in
/// this file; it always resolves to "no snapshot yet", which none of these
/// tests assert on.
class _FakeNpsAggregateRepository implements NpsAggregateRepository {
  @override
  Future<AppResult<NpsAggregateSnapshot?>> getSnapshot({
    required String organizationId,
    required String companyId,
    required NpsAggregateScope scope,
    required String scopeId,
    required String periodKey,
  }) async => const AppSuccess<NpsAggregateSnapshot?>(null);
}

/// Never actually invoked by any test in this file (none of them tap the
/// "Gerar resumo" button) — only exists so `RepresentativeDashboardPage`'s
/// required `createWalletSummaryCubit` has something real to construct.
class _UncalledWalletSummaryRepository implements WalletSummaryRepository {
  @override
  Future<AppResult<WalletSummary>> generate({
    required String organizationId,
    required String companyId,
    required String sellerId,
  }) => throw UnimplementedError(
    'WalletSummaryRepository.generate should never be called in these tests.',
  );
}

/// Unlike `_UncalledWalletSummaryRepository` above, `DailyRepSummaryCard`
/// loads automatically on creation (TASK-188 — it never costs an LLM call,
/// so there is no "Gerar resumo" gate), so this fake really is called by
/// every test in this file; it always resolves to the same harmless
/// "not generated yet" state, which none of these tests assert on.
class _FakeDailyRepSummaryRepository implements DailyRepSummaryRepository {
  @override
  Future<AppResult<DailyRepSummary>> load({
    required String organizationId,
    required String sellerId,
    String? dateKey,
  }) async => const AppSuccess<DailyRepSummary>(
    DailyRepSummary(
      status: DailyRepSummaryResultStatus.notGeneratedYet,
      dateKey: '2026-09-04',
    ),
  );
}

void main() {
  late _LoadDashboard loadDashboard;
  final _MockMembershipRepository dailyRepSummaryMembershipRepository =
      _MockMembershipRepository();
  const filters = RepresentativeDashboardFilters(
    companyId: 'company-1',
    sellerId: 'rep-1',
    year: 2026,
    month: 9,
  );
  final followUp = CrmTask(
    id: 'task-1',
    organizationId: 'org-1',
    title: 'Retornar para a Loja Sol',
    activityId: 'activity-1',
    responsibleUserId: 'rep-1',
    dueAt: DateTime.utc(2026, 9, 4, 15),
    priority: CrmTaskPriority.high,
    status: CrmTaskStatus.pending,
    createdAt: DateTime.utc(2026),
    createdBy: 'rep-1',
    updatedAt: DateTime.utc(2026),
    updatedBy: 'rep-1',
    version: 1,
    syncStatus: CrmTaskSyncStatus.synced,
  );

  RepresentativeDashboardSnapshot snapshot({bool cached = false}) =>
      RepresentativeDashboardSnapshot(
        salesToday: const ExecutiveDashboardMetric.available(value: 120),
        salesMonth: const ExecutiveDashboardMetric.available(value: 3500),
        targetAchievement: const ExecutiveDashboardMetric.notCalculated(),
        portfolioPositivation: const ExecutiveDashboardMetric.available(
          value: 40,
        ),
        teamRank: const ExecutiveDashboardMetric.available(value: 2),
        followUps: <CrmTask>[followUp],
        customers: const <RepresentativeCustomerHighlight>[],
        lastUpdatedAt: DateTime.utc(2026, 9, 4, 12),
        isFromLocalCache: cached,
      );

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
    registerFallbackValue(filters);
  });

  setUp(() {
    loadDashboard = _LoadDashboard();
    // `DailyRepSummaryCard` auto-loads via a real `LoadDailyRepSummaryUseCase`
    // + `RepresentativeDashboardVisibilityService` (see `page()` below), so
    // the self-access membership lookup it triggers must be stubbed in every
    // test, mirroring `generate_wallet_summary_use_case_test.dart`'s own
    // "seller requesting their own wallet" setup.
    when(
      () => dailyRepSummaryMembershipRepository.getByUser(
        organizationId: 'org-1',
        userId: 'rep-1',
      ),
    ).thenAnswer(
      (_) async => AppSuccess<Membership>(
        Membership(
          id: 'rep-1',
          organizationId: 'org-1',
          userId: 'rep-1',
          roleId: 'SALES_REP',
          roleName: 'SALES_REP',
          teamIds: const <String>[],
          status: MembershipStatus.active,
          version: 1,
          createdAt: DateTime.utc(2026, 1, 1),
          createdBy: 'rep-1',
          updatedAt: DateTime.utc(2026, 1, 1),
          updatedBy: 'rep-1',
        ),
      ),
    );
  });

  void setWidth(WidgetTester tester, double width) {
    tester.view.physicalSize = Size(width, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget page({required ValueChanged<CrmTask> onOpenCrmActivity}) {
    return RepresentativeDashboardPage(
      organizationId: 'org-1',
      requesterUserId: 'rep-1',
      initialFilters: filters,
      createBloc: () =>
          RepresentativeDashboardBloc(loadDashboard, FakeAnalyticsService()),
      createWalletSummaryCubit: () => WalletSummaryCubit(
        GenerateWalletSummaryUseCase(
          _UncalledWalletSummaryRepository(),
          RepresentativeDashboardVisibilityService(
            _MockMembershipRepository(),
            _MockTeamRepository(),
          ),
          FakeAnalyticsService(),
        ),
      ),
      createDailyRepSummaryCubit: () => DailyRepSummaryCubit(
        LoadDailyRepSummaryUseCase(
          _FakeDailyRepSummaryRepository(),
          RepresentativeDashboardVisibilityService(
            dailyRepSummaryMembershipRepository,
            _MockTeamRepository(),
          ),
          FakeAnalyticsService(),
        ),
      ),
      createNpsScoreCardCubit: () => NpsScoreCardCubit(
        LoadNpsAggregateTrendUseCase(_FakeNpsAggregateRepository()),
        FakeAnalyticsService(),
      ),
      onOpenCrmActivity: onOpenCrmActivity,
      onOpenCustomer: (_) {},
      onOpenInsight: (_) {},
    );
  }

  void stubSnapshot(RepresentativeDashboardSnapshot value) {
    when(
      () => loadDashboard(
        organizationId: 'org-1',
        requesterUserId: 'rep-1',
        filters: filters,
      ),
    ).thenAnswer((_) async => AppSuccess(value));
  }

  testWidgets('mobile uses one KPI column and shows stale offline data', (
    tester,
  ) async {
    setWidth(tester, 390);
    stubSnapshot(snapshot(cached: true));
    await pumpApp(tester, page(onOpenCrmActivity: (_) {}));
    await tester.pumpAndSettle();

    final grid = tester.widget<GridView>(
      find.byKey(const Key('representative-kpi-grid')),
    );
    expect(
      (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      1,
    );
    expect(find.textContaining('Você está offline'), findsOneWidget);
    expect(find.widgetWithText(AppKpiCard, 'Venda hoje'), findsOneWidget);
  });

  testWidgets('desktop lays KPI cards in multiple columns', (tester) async {
    setWidth(tester, 1280);
    stubSnapshot(snapshot());
    await pumpApp(tester, page(onOpenCrmActivity: (_) {}));
    await tester.pumpAndSettle();

    final grid = tester.widget<GridView>(
      find.byKey(const Key('representative-kpi-grid')),
    );
    expect(
      (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      greaterThan(1),
    );
  });

  testWidgets('follow-up opens the linked CRM activity flow', (tester) async {
    setWidth(tester, 390);
    stubSnapshot(snapshot());
    CrmTask? opened;
    await pumpApp(tester, page(onOpenCrmActivity: (task) => opened = task));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Retornar para a Loja Sol'));
    await tester.tap(find.text('Retornar para a Loja Sol'));
    expect(opened?.activityId, 'activity-1');
  });
}
