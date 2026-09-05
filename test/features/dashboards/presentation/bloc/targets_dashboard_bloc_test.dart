import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/dashboards/dashboards.dart';

class _LoadTargets extends Mock implements LoadTargetsDashboardUseCase {}

void main() {
  late _LoadTargets load;
  late FakeAnalyticsService analytics;
  const filters = TargetsDashboardFilters(
    companyId: 'company-1',
    year: 2026,
    month: 1,
  );
  final snapshot = TargetsDashboardSnapshot(
    root: const TargetsDashboardRow(
      id: 'company-1',
      label: 'Organização',
      level: TargetsDashboardLevel.organization,
      metric: null,
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

  setUpAll(() => registerFallbackValue(filters));

  setUp(() {
    load = _LoadTargets();
    analytics = FakeAnalyticsService();
    when(
      () => load(
        organizationId: any(named: 'organizationId'),
        userId: any(named: 'userId'),
        filters: any(named: 'filters'),
      ),
    ).thenAnswer((_) async => AppSuccess<TargetsDashboardSnapshot>(snapshot));
  });

  blocTest<TargetsDashboardBloc, TargetsDashboardState>(
    'loads, filters and records dashboard_viewed as targets',
    build: () => TargetsDashboardBloc(load, analytics),
    act: (bloc) async {
      bloc.add(
        const TargetsDashboardStarted(
          organizationId: 'org-1',
          userId: 'admin-1',
          filters: filters,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      bloc.add(
        TargetsDashboardFiltersChanged(filters.copyWith(teamId: 'team-a')),
      );
    },
    wait: Duration.zero,
    verify: (_) {
      expect(analytics.loggedEvents, hasLength(2));
      expect(analytics.loggedEvents.last.name, AnalyticsEvents.dashboardViewed);
      expect(
        analytics.loggedEvents.last.parameters!['dashboard_type'],
        'targets',
      );
    },
  );

  blocTest<TargetsDashboardBloc, TargetsDashboardState>(
    'drills organization to team to seller and back',
    build: () => TargetsDashboardBloc(load, analytics),
    act: (bloc) async {
      bloc.add(
        const TargetsDashboardStarted(
          organizationId: 'org-1',
          userId: 'admin-1',
          filters: filters,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      bloc.add(const TargetsDashboardDrilledDown('team-a'));
      bloc.add(const TargetsDashboardDrilledDown('seller-1'));
      bloc.add(const TargetsDashboardDrilledUp());
    },
    verify: (bloc) => expect(bloc.state.drillPath, <String>['team-a']),
  );
}
