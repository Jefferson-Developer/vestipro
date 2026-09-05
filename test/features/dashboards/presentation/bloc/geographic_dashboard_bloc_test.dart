import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/dashboards/dashboards.dart';

class _Load extends Mock implements LoadGeographicDashboardUseCase {}

class _Analytics extends Mock implements AnalyticsService {}

void main() {
  late _Load load;
  late _Analytics analytics;
  const filters = GeographicDashboardFilters(
    companyId: 'company-1',
    monthKey: '2026-09',
  );
  const city = GeographicDashboardRow(
    id: 'SC:Blumenau',
    label: 'Blumenau',
    level: GeographicDashboardLevel.city,
    revenue: 100,
    orderCount: 1,
    activeCustomerCount: 1,
    itemQuantity: 2,
    customerIds: <String>['c1'],
    orderIds: <String>['o1'],
  );
  const snapshot = GeographicDashboardSnapshot(
    regions: <GeographicDashboardRow>[
      GeographicDashboardRow(
        id: 'sul',
        label: 'Sul',
        level: GeographicDashboardLevel.region,
        revenue: 100,
        orderCount: 1,
        activeCustomerCount: 1,
        itemQuantity: 2,
        children: <GeographicDashboardRow>[city],
      ),
    ],
    generatedAt: null,
    isFromLocalCache: false,
  );

  setUp(() {
    load = _Load();
    analytics = _Analytics();
    when(
      () => load(organizationId: 'org-1', userId: 'user-1', filters: filters),
    ).thenAnswer((_) async => const AppSuccess(snapshot));
    when(
      () => analytics.logEvent(any(), parameters: any(named: 'parameters')),
    ).thenAnswer((_) async {});
  });

  blocTest<GeographicDashboardBloc, GeographicDashboardState>(
    'loads the complete hierarchy and records dashboard_viewed',
    build: () => GeographicDashboardBloc(load, analytics),
    act: (bloc) => bloc.add(
      const GeographicDashboardStarted(
        organizationId: 'org-1',
        userId: 'user-1',
        filters: filters,
      ),
    ),
    wait: Duration.zero,
    expect: () => <dynamic>[
      isA<GeographicDashboardState>().having(
        (state) => state.status,
        'status',
        GeographicDashboardStatus.loading,
      ),
      isA<GeographicDashboardState>().having(
        (state) => state.status,
        'status',
        GeographicDashboardStatus.loading,
      ),
      isA<GeographicDashboardState>().having(
        (state) => state.snapshot?.regions.single.children.single.label,
        'city',
        'Blumenau',
      ),
    ],
    verify: (_) => verify(
      () => analytics.logEvent(
        AnalyticsEvents.dashboardViewed,
        parameters: any(named: 'parameters'),
      ),
    ).called(1),
  );

  blocTest<GeographicDashboardBloc, GeographicDashboardState>(
    'selects an area for customer/order drill-down',
    build: () => GeographicDashboardBloc(load, analytics),
    seed: () => const GeographicDashboardState(
      status: GeographicDashboardStatus.ready,
      organizationId: 'org-1',
      userId: 'user-1',
      filters: filters,
      snapshot: snapshot,
    ),
    act: (bloc) => bloc.add(const GeographicDashboardDrillDownRequested(city)),
    expect: () => <dynamic>[
      isA<GeographicDashboardState>()
          .having(
            (state) => state.selectedArea?.customerIds,
            'customers',
            <String>['c1'],
          )
          .having((state) => state.selectedArea?.orderIds, 'orders', <String>[
            'o1',
          ]),
    ],
  );
}
