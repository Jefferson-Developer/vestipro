import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/dashboards/dashboards.dart';

import '../../../../core/design_system/components/test_pump_app.dart';

class _LoadTargets extends Mock implements LoadTargetsDashboardUseCase {}

void main() {
  late _LoadTargets load;
  final snapshot = TargetsDashboardSnapshot(
    root: const TargetsDashboardRow(
      id: 'company-1',
      label: 'Organização',
      level: TargetsDashboardLevel.organization,
      metric: TargetsDashboardMetric(
        targetValue: 1000,
        realizedValue: 500,
        achievementPercentage: 50,
        projectedValue: 900,
        projectedAchievementPercentage: 90,
      ),
      children: <TargetsDashboardRow>[
        TargetsDashboardRow(
          id: 'team-a',
          label: 'Equipe A',
          level: TargetsDashboardLevel.team,
          metric: null,
          children: <TargetsDashboardRow>[
            TargetsDashboardRow(
              id: 'seller-1',
              label: 'Ana',
              level: TargetsDashboardLevel.seller,
              metric: null,
              isBelowTargetInsightActive: true,
            ),
          ],
        ),
      ],
    ),
    ranking: const [],
    availableTeamIds: const ['team-a'],
    availableSellerIds: const ['seller-1'],
    generatedAt: DateTime.utc(2026),
    isFromLocalCache: false,
  );

  setUpAll(
    () => registerFallbackValue(
      const TargetsDashboardFilters(
        companyId: 'fallback',
        year: 2024,
        month: 1,
      ),
    ),
  );

  setUp(() {
    load = _LoadTargets();
    when(
      () => load(
        organizationId: any(named: 'organizationId'),
        userId: any(named: 'userId'),
        filters: any(named: 'filters'),
      ),
    ).thenAnswer((_) async => AppSuccess<TargetsDashboardSnapshot>(snapshot));
  });

  Widget page() => TargetsDashboardPage(
    organizationId: 'org-1',
    userId: 'admin-1',
    initialFilters: const TargetsDashboardFilters(
      companyId: 'company-1',
      year: 2026,
      month: 1,
    ),
    createBloc: () => TargetsDashboardBloc(load, FakeAnalyticsService()),
    onOpenOpportunities: (_) {},
  );

  testWidgets('desktop renders an expandable hierarchy', (tester) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpApp(tester, page());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('targets-desktop-hierarchy')), findsOneWidget);
    expect(find.text('Equipe A'), findsOneWidget);
  });

  testWidgets('mobile navigates hierarchy one level at a time', (tester) async {
    tester.view.physicalSize = const Size(420, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpApp(tester, page());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('targets-mobile-hierarchy')), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('drill-team-a')),
    );
    await tester.tap(find.byKey(const ValueKey<String>('drill-team-a')));
    await tester.pump();
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Voltar um nível'), findsOneWidget);
  });
}
