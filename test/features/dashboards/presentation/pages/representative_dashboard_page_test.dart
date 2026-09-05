import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/crm/crm.dart';
import 'package:vestipro/features/dashboards/dashboards.dart';

import '../../../../core/design_system/components/test_pump_app.dart';

class _LoadDashboard extends Mock
    implements LoadRepresentativeDashboardUseCase {}

void main() {
  late _LoadDashboard loadDashboard;
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
