import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/dashboards/dashboards.dart';

class _LoadDashboard extends Mock implements LoadFunnelDashboardUseCase {}

void main() {
  late _LoadDashboard loadDashboard;
  late FakeAnalyticsService analytics;
  const filters = FunnelDashboardFilters(
    monthKey: '2026-09',
    companyId: 'company-1',
  );

  setUpAll(() => registerFallbackValue(filters));
  setUp(() {
    loadDashboard = _LoadDashboard();
    analytics = FakeAnalyticsService();
  });

  FunnelDashboardBloc buildBloc() =>
      FunnelDashboardBloc(loadDashboard, analytics);

  final snapshot = FunnelDashboardSnapshot(
    stages: const <FunnelStageSnapshot>[
      FunnelStageSnapshot(
        stageId: 'a',
        name: 'A',
        colorHex: '#336699',
        order: 0,
        opportunityCount: 1,
        totalValue: 100,
        weightedValue: 50,
        averageAgingDays: 2,
        conversionToNext: 0,
      ),
      FunnelStageSnapshot(
        stageId: 'b',
        name: 'B',
        colorHex: '#336699',
        order: 1,
        opportunityCount: 0,
        totalValue: 0,
        weightedValue: 0,
        averageAgingDays: 0,
        conversionToNext: null,
      ),
    ],
    lossReasons: const <FunnelLossReasonSnapshot>[],
    pipelineWeightedValue: 50,
    generatedAt: DateTime.utc(2026, 9, 10),
  );

  blocTest<FunnelDashboardBloc, FunnelDashboardState>(
    'loads full funnel, including empty stage, conversion and weighted value',
    setUp: () {
      when(
        () => loadDashboard(
          organizationId: 'org-1',
          userId: 'manager-1',
          filters: filters,
        ),
      ).thenAnswer((_) async => AppSuccess(snapshot));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(
      const FunnelDashboardStarted(
        organizationId: 'org-1',
        userId: 'manager-1',
        filters: filters,
      ),
    ),
    expect: () => <Object>[
      isA<FunnelDashboardState>().having(
        (state) => state.status,
        'loading',
        FunnelDashboardStatus.loading,
      ),
      isA<FunnelDashboardState>()
          .having((state) => state.status, 'ready', FunnelDashboardStatus.ready)
          .having(
            (state) => state.snapshot!.stages[1].opportunityCount,
            'empty stage',
            0,
          )
          .having(
            (state) => state.snapshot!.stages.first.conversionToNext,
            'conversion',
            0,
          )
          .having(
            (state) => state.snapshot!.pipelineWeightedValue,
            'weighted',
            50,
          ),
    ],
    verify: (_) => expect(
      analytics.loggedEvents.single.parameters?['dashboard_type'],
      'funnel',
    ),
  );

  blocTest<FunnelDashboardBloc, FunnelDashboardState>(
    'maps an RBAC scope denial to forbidden',
    setUp: () {
      when(
        () => loadDashboard(
          organizationId: 'org-1',
          userId: 'manager-1',
          filters: any(named: 'filters'),
        ),
      ).thenAnswer(
        (_) async => const AppFailure<FunnelDashboardSnapshot>(
          PermissionFailure('denied'),
        ),
      );
    },
    build: buildBloc,
    act: (bloc) => bloc.add(
      const FunnelDashboardStarted(
        organizationId: 'org-1',
        userId: 'manager-1',
        filters: FunnelDashboardFilters(
          monthKey: '2026-09',
          companyId: 'company-1',
          sellerId: 'other-rep',
        ),
      ),
    ),
    expect: () => <Object>[
      isA<FunnelDashboardState>(),
      isA<FunnelDashboardState>().having(
        (state) => state.status,
        'forbidden',
        FunnelDashboardStatus.forbidden,
      ),
    ],
  );
}
