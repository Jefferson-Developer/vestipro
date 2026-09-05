import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/dashboards/dashboards.dart';

import '../../../../core/design_system/components/test_pump_app.dart';

class _LoadDashboard extends Mock implements LoadFunnelDashboardUseCase {}

void main() {
  late _LoadDashboard loadDashboard;
  const filters = FunnelDashboardFilters(
    monthKey: '2026-09',
    companyId: 'company-1',
  );
  final snapshot = FunnelDashboardSnapshot(
    stages: const <FunnelStageSnapshot>[
      FunnelStageSnapshot(
        stageId: 'qualification',
        name: 'Qualificação',
        colorHex: '#336699',
        order: 0,
        opportunityCount: 1,
        totalValue: 1000,
        weightedValue: 500,
        averageAgingDays: 3,
        conversionToNext: 0,
      ),
      FunnelStageSnapshot(
        stageId: 'proposal',
        name: 'Proposta',
        colorHex: '#996633',
        order: 1,
        opportunityCount: 0,
        totalValue: 0,
        weightedValue: 0,
        averageAgingDays: 0,
        conversionToNext: null,
      ),
    ],
    lossReasons: const <FunnelLossReasonSnapshot>[],
    pipelineWeightedValue: 500,
    generatedAt: DateTime.utc(2026, 9, 10),
  );

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
    registerFallbackValue(filters);
  });
  setUp(() {
    loadDashboard = _LoadDashboard();
    when(
      () => loadDashboard(
        organizationId: 'org-1',
        userId: 'rep-1',
        filters: filters,
      ),
    ).thenAnswer((_) async => AppSuccess(snapshot));
  });

  void setWidth(WidgetTester tester, double width) {
    tester.view.physicalSize = Size(width, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget page(ValueChanged<String> onOpen) => FunnelDashboardPage(
    organizationId: 'org-1',
    userId: 'rep-1',
    initialFilters: filters,
    createBloc: () =>
        FunnelDashboardBloc(loadDashboard, FakeAnalyticsService()),
    onOpenStageOpportunities: onOpen,
  );

  testWidgets('renders stage cards as a mobile list and opens drill-down', (
    tester,
  ) async {
    setWidth(tester, 390);
    String? opened;
    await pumpApp(tester, page((stageId) => opened = stageId));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('funnel-mobile-stage-list')), findsOneWidget);
    expect(find.textContaining('1 oportunidades'), findsOneWidget);
    expect(find.textContaining('R\$'), findsWidgets);
    await tester.ensureVisible(find.text('Qualificação'));
    await tester.tap(find.text('Qualificação'));
    expect(opened, 'qualification');
  });

  testWidgets('renders horizontally stacked stages on desktop', (tester) async {
    setWidth(tester, 1280);
    await pumpApp(tester, page((_) {}));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('funnel-desktop-stacked-stages')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('funnel-mobile-stage-list')), findsNothing);
  });
}
