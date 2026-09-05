import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/dashboards/dashboards.dart';

class _LoadDashboard extends Mock
    implements LoadRepresentativeDashboardUseCase {}

void main() {
  late _LoadDashboard loadDashboard;
  late FakeAnalyticsService analytics;
  const filters = RepresentativeDashboardFilters(
    companyId: 'company-1',
    sellerId: 'rep-1',
    year: 2026,
    month: 9,
  );

  const noValue = ExecutiveDashboardMetric.notCalculated();
  RepresentativeDashboardSnapshot snapshot({bool cached = false}) =>
      RepresentativeDashboardSnapshot(
        salesToday: const ExecutiveDashboardMetric.available(value: 120),
        salesMonth: const ExecutiveDashboardMetric.available(value: 3500),
        targetAchievement: noValue,
        portfolioPositivation: const ExecutiveDashboardMetric.available(
          value: 40,
        ),
        teamRank: noValue,
        followUps: const [],
        customers: const [],
        lastUpdatedAt: DateTime.utc(2026, 9, 4, 12),
        isFromLocalCache: cached,
      );

  setUpAll(() => registerFallbackValue(filters));

  setUp(() {
    loadDashboard = _LoadDashboard();
    analytics = FakeAnalyticsService();
  });

  RepresentativeDashboardBloc buildBloc() =>
      RepresentativeDashboardBloc(loadDashboard, analytics);

  blocTest<RepresentativeDashboardBloc, RepresentativeDashboardState>(
    'loads the complete dashboard, including empty follow-ups and absent target',
    setUp: () {
      when(
        () => loadDashboard(
          organizationId: 'org-1',
          requesterUserId: 'rep-1',
          filters: filters,
        ),
      ).thenAnswer((_) async => AppSuccess(snapshot()));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(
      const RepresentativeDashboardStarted(
        organizationId: 'org-1',
        requesterUserId: 'rep-1',
        initialFilters: filters,
      ),
    ),
    expect: () => <Object>[
      isA<RepresentativeDashboardState>().having(
        (state) => state.status,
        'status',
        RepresentativeDashboardStatus.loading,
      ),
      isA<RepresentativeDashboardState>()
          .having(
            (state) => state.status,
            'status',
            RepresentativeDashboardStatus.ready,
          )
          .having(
            (state) => state.snapshot!.targetAchievement.status,
            'target status',
            ExecutiveDashboardMetricStatus.notCalculated,
          )
          .having((state) => state.snapshot!.followUps, 'follow-ups', isEmpty),
    ],
    verify: (_) {
      expect(
        analytics.loggedEvents.single.parameters?['dashboard_type'],
        'representative',
      );
    },
  );

  blocTest<RepresentativeDashboardBloc, RepresentativeDashboardState>(
    'exposes that a successful snapshot came from the offline cache',
    setUp: () {
      when(
        () => loadDashboard(
          organizationId: 'org-1',
          requesterUserId: 'rep-1',
          filters: filters,
        ),
      ).thenAnswer((_) async => AppSuccess(snapshot(cached: true)));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(
      const RepresentativeDashboardStarted(
        organizationId: 'org-1',
        requesterUserId: 'rep-1',
        initialFilters: filters,
      ),
    ),
    expect: () => <Object>[
      isA<RepresentativeDashboardState>(),
      isA<RepresentativeDashboardState>().having(
        (state) => state.snapshot?.isFromLocalCache,
        'cached',
        isTrue,
      ),
    ],
  );

  blocTest<RepresentativeDashboardBloc, RepresentativeDashboardState>(
    'maps the RBAC denial to forbidden',
    setUp: () {
      when(
        () => loadDashboard(
          organizationId: 'org-1',
          requesterUserId: 'rep-1',
          filters: filters,
        ),
      ).thenAnswer(
        (_) async => const AppFailure<RepresentativeDashboardSnapshot>(
          PermissionFailure('denied'),
        ),
      );
    },
    build: buildBloc,
    act: (bloc) => bloc.add(
      const RepresentativeDashboardStarted(
        organizationId: 'org-1',
        requesterUserId: 'rep-1',
        initialFilters: filters,
      ),
    ),
    expect: () => <Object>[
      isA<RepresentativeDashboardState>(),
      isA<RepresentativeDashboardState>().having(
        (state) => state.status,
        'status',
        RepresentativeDashboardStatus.forbidden,
      ),
    ],
  );
}
