import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/dashboards/dashboards.dart';

class _Repository extends Mock implements AggregationRepository {}

class _Visibility extends Mock implements ExecutiveDashboardVisibilityService {}

void main() {
  late _Repository repository;
  late _Visibility visibility;
  late LoadGeographicDashboardUseCase useCase;
  const filters = GeographicDashboardFilters(
    companyId: 'company-1',
    monthKey: '2026-09',
  );

  setUpAll(() => registerFallbackValue(AggregationDimension.regionMonthly));

  setUp(() {
    repository = _Repository();
    visibility = _Visibility();
    useCase = LoadGeographicDashboardUseCase(repository, visibility);
    when(
      () => visibility.resolve(organizationId: 'org-1', userId: 'user-1'),
    ).thenAnswer(
      (_) async => const AppSuccess(
        ExecutiveDashboardVisibilityFilter(
          organizationId: 'org-1',
          userId: 'user-1',
          mode: ExecutiveDashboardVisibilityMode.allOrganization,
        ),
      ),
    );
  });

  test(
    'builds region -> state -> city KPIs and drill-down identifiers',
    () async {
      when(
        () => repository.listByPeriod(
          organizationId: 'org-1',
          dimension: AggregationDimension.regionMonthly,
          companyId: 'company-1',
          periodKey: '2026-09',
          limit: 500,
        ),
      ).thenAnswer(
        (_) async => AppSuccess(<AggregationSnapshot>[
          _snapshot(
            'SC:Blumenau',
            revenue: 1200,
            orders: 3,
            labels: const <String, String>{
              'state': 'SC',
              'city': 'Blumenau',
              'customerIds': 'c1,c2',
              'orderIds': 'o1,o2,o3',
              'topProducts': 'Camisa:8|Calça:3',
            },
          ),
          _snapshot(
            'PR:Curitiba',
            revenue: 800,
            orders: 2,
            labels: const <String, String>{
              'state': 'PR',
              'city': 'Curitiba',
              'customerIds': 'c3',
              'orderIds': 'o4,o5',
              'topProducts': 'Camisa:2',
            },
          ),
        ]),
      );
      final result = await useCase(
        organizationId: 'org-1',
        userId: 'user-1',
        filters: filters,
      );
      final dashboard =
          (result as AppSuccess<GeographicDashboardSnapshot>).value;
      expect(dashboard.regions.single.label, 'Sul');
      expect(dashboard.regions.single.children, hasLength(2));
      expect(dashboard.revenue, 2000);
      expect(dashboard.activeCustomerCount, 3);
      expect(
        dashboard.regions.single.customerIds,
        containsAll(<String>['c1', 'c2', 'c3']),
      );
    expect(dashboard.regions.single.topProducts.first.name, 'Camisa');
    expect(dashboard.hasMapData, isFalse);
    },
  );

  test(
    'returns an empty dashboard when the period has no geographic rows',
    () async {
      when(
        () => repository.listByPeriod(
          organizationId: any(named: 'organizationId'),
          dimension: any(named: 'dimension'),
          companyId: any(named: 'companyId'),
          periodKey: any(named: 'periodKey'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => const AppSuccess(<AggregationSnapshot>[]));
      final result = await useCase(
        organizationId: 'org-1',
        userId: 'user-1',
        filters: filters,
      );
      expect(
        (result as AppSuccess<GeographicDashboardSnapshot>).value.regions,
        isEmpty,
      );
    },
  );

  test('RBAC rejects a company outside the manager scope', () async {
    when(
      () => visibility.resolve(organizationId: 'org-1', userId: 'user-1'),
    ).thenAnswer(
      (_) async => const AppSuccess(
        ExecutiveDashboardVisibilityFilter(
          organizationId: 'org-1',
          userId: 'user-1',
          mode: ExecutiveDashboardVisibilityMode.ownScope,
          allowedCompanyIds: <String>{'company-2'},
          allowedTeamIds: <String>{'team-1'},
        ),
      ),
    );
    final result = await useCase(
      organizationId: 'org-1',
      userId: 'user-1',
      filters: filters,
    );
    expect(result, isA<AppFailure<GeographicDashboardSnapshot>>());
    verifyNever(
      () => repository.listByPeriod(
        organizationId: any(named: 'organizationId'),
        dimension: any(named: 'dimension'),
        companyId: any(named: 'companyId'),
        periodKey: any(named: 'periodKey'),
        limit: any(named: 'limit'),
      ),
    );
  });
}

AggregationSnapshot _snapshot(
  String scopeId, {
  required double revenue,
  required int orders,
  required Map<String, String> labels,
}) => AggregationSnapshot(
  organizationId: 'org-1',
  companyId: 'company-1',
  dimension: AggregationDimension.regionMonthly,
  scopeId: scopeId,
  periodKey: '2026-09',
  revenueGross: revenue,
  revenueNet: revenue,
  discountAmount: 0,
  orderCount: orders,
  itemQuantity: 10,
  labels: labels,
  generatedAt: DateTime.utc(2026, 9, 4),
  version: 1,
);
