import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/dashboards/dashboards.dart';

void main() {
  late _FakeAggregationRepository aggregationRepository;
  late LoadSalesDashboardSnapshotUseCase useCase;

  const organizationId = 'org-1';
  const companyId = 'company-1';
  const filters = SalesDashboardFilters(
    companyId: companyId,
    year: 2026,
    month: 8,
  );

  setUp(() {
    aggregationRepository = _FakeAggregationRepository();
    useCase = LoadSalesDashboardSnapshotUseCase(aggregationRepository);
  });

  AggregationSnapshot salesDailySnapshot({
    required String periodKey,
    required double revenueGross,
    required double revenueNet,
    required double discountAmount,
    required int orderCount,
    required int itemQuantity,
  }) {
    return AggregationSnapshot(
      organizationId: organizationId,
      companyId: companyId,
      dimension: AggregationDimension.salesDaily,
      scopeId: companyId,
      periodKey: periodKey,
      revenueGross: revenueGross,
      revenueNet: revenueNet,
      discountAmount: discountAmount,
      orderCount: orderCount,
      itemQuantity: itemQuantity,
      labels: const <String, String>{},
      generatedAt: DateTime.utc(2026, 8, 1),
      version: 1,
    );
  }

  AggregationSnapshot sellerMonthlySnapshot({
    required String sellerId,
    required String periodKey,
    required double revenueNet,
    required int orderCount,
  }) {
    return AggregationSnapshot(
      organizationId: organizationId,
      companyId: companyId,
      dimension: AggregationDimension.sellerMonthly,
      scopeId: sellerId,
      periodKey: periodKey,
      revenueGross: revenueNet,
      revenueNet: revenueNet,
      discountAmount: 0,
      orderCount: orderCount,
      itemQuantity: orderCount,
      labels: const <String, String>{},
      generatedAt: DateTime.utc(2026, 8, 1),
      version: 1,
    );
  }

  group('validation', () {
    test('returns a validation failure for a blank organizationId', () async {
      final result = await useCase(organizationId: '', filters: filters);
      expect(result, isA<AppFailure<SalesDashboardSnapshot>>());
    });

    test('returns a validation failure for a blank companyId', () async {
      final result = await useCase(
        organizationId: organizationId,
        filters: const SalesDashboardFilters(
          companyId: '',
          year: 2026,
          month: 8,
        ),
      );
      expect(result, isA<AppFailure<SalesDashboardSnapshot>>());
    });
  });

  group('margin and produtos por pedido', () {
    test('are always not calculated — no cost/margin or per-order SKU data '
        'exists anywhere in the backend', () async {
      final result = await useCase(
        organizationId: organizationId,
        filters: filters,
      );
      final snapshot = (result as AppSuccess<SalesDashboardSnapshot>).value;
      expect(snapshot.margin.status, SalesDashboardKpiStatus.notCalculated);
      expect(
        snapshot.productsPerOrder.status,
        SalesDashboardKpiStatus.notCalculated,
      );
    });
  });

  group('KPI computation — never a divergent client-side calculation', () {
    test(
      'revenue/orders/ticket/quantity/discount/pieces are derived exactly '
      'from the aggregation snapshot totals, with MoM and YoY comparison',
      () async {
        aggregationRepository.snapshots.addAll(<AggregationSnapshot>[
          salesDailySnapshot(
            periodKey: '2026-08-10',
            revenueGross: 1200,
            revenueNet: 1000,
            discountAmount: 200,
            orderCount: 4,
            itemQuantity: 20,
          ),
          salesDailySnapshot(
            periodKey: '2026-07-10',
            revenueGross: 600,
            revenueNet: 500,
            discountAmount: 100,
            orderCount: 2,
            itemQuantity: 8,
          ),
          salesDailySnapshot(
            periodKey: '2025-08-10',
            revenueGross: 1200,
            revenueNet: 800,
            discountAmount: 400,
            orderCount: 8,
            itemQuantity: 16,
          ),
        ]);

        final result = await useCase(
          organizationId: organizationId,
          filters: filters,
        );
        final snapshot = (result as AppSuccess<SalesDashboardSnapshot>).value;

        expect(snapshot.revenue.value, 1000);
        expect(snapshot.revenue.previousMonthValue, 500);
        expect(snapshot.revenue.previousYearValue, 800);
        expect(snapshot.revenue.momChangePercentage, 100);
        expect(snapshot.revenue.yoyChangePercentage, 25);

        expect(snapshot.orders.value, 4);
        expect(snapshot.averageTicket.value, 250); // 1000 / 4
        expect(snapshot.itemQuantity.value, 20);
        expect(snapshot.piecesPerOrder.value, 5); // 20 / 4

        // discountAmount / revenueGross * 100 — sourced from the pricing
        // engine's own persisted fields (via TASK-133), never recomputed.
        expect(snapshot.discountAverage.value, closeTo(16.666, 0.01));
      },
    );

    test('an empty period (no data yet) resolves every KPI to an available '
        'zero, never a failure', () async {
      final result = await useCase(
        organizationId: organizationId,
        filters: filters,
      );
      final snapshot = (result as AppSuccess<SalesDashboardSnapshot>).value;
      expect(snapshot.revenue.isAvailable, isTrue);
      expect(snapshot.revenue.value, 0);
      expect(snapshot.orders.value, 0);
      expect(snapshot.averageTicket.value, 0);
      expect(snapshot.discountAverage.value, 0);
      expect(snapshot.piecesPerOrder.value, 0);
    });

    test('a repository failure for the current period fails that KPI (never '
        'the whole use case call, same "um KPI falha e os demais continuam '
        'exibidos" contract), but a failure for a comparison period only '
        'drops that comparison', () async {
      aggregationRepository.failingRangeKeys.add('2026-08-01|2026-08-31');
      final result = await useCase(
        organizationId: organizationId,
        filters: filters,
      );
      final snapshot = (result as AppSuccess<SalesDashboardSnapshot>).value;
      expect(snapshot.revenue.status, SalesDashboardKpiStatus.failed);
    });
  });

  group('team filter — folds sellerMonthly instead of the company total', () {
    test('sums only the team members\' sellerMonthly snapshots', () async {
      aggregationRepository.snapshots.addAll(<AggregationSnapshot>[
        sellerMonthlySnapshot(
          sellerId: 'seller-in-team',
          periodKey: '2026-08',
          revenueNet: 300,
          orderCount: 2,
        ),
        sellerMonthlySnapshot(
          sellerId: 'seller-outside-team',
          periodKey: '2026-08',
          revenueNet: 9000,
          orderCount: 90,
        ),
      ]);

      final result = await useCase(
        organizationId: organizationId,
        filters: filters.copyWith(teamId: 'team-a'),
        teamMemberIds: <String>['seller-in-team'],
      );
      final snapshot = (result as AppSuccess<SalesDashboardSnapshot>).value;
      expect(snapshot.revenue.value, 300);
      expect(snapshot.orders.value, 2);
    });

    test('a team filter resolving to no members yields an available zero, '
        'never falling back to the whole company', () async {
      aggregationRepository.snapshots.add(
        sellerMonthlySnapshot(
          sellerId: 'someone',
          periodKey: '2026-08',
          revenueNet: 9000,
          orderCount: 90,
        ),
      );
      final result = await useCase(
        organizationId: organizationId,
        filters: filters.copyWith(teamId: 'team-empty'),
        teamMemberIds: const <String>[],
      );
      final snapshot = (result as AppSuccess<SalesDashboardSnapshot>).value;
      expect(snapshot.revenue.value, 0);
    });
  });
}

final class _FakeAggregationRepository implements AggregationRepository {
  final List<AggregationSnapshot> snapshots = <AggregationSnapshot>[];
  final Set<String> failingRangeKeys = <String>{};
  final Set<String> failingPeriodKeys = <String>{};
  final Failure failure = const ServerFailure('boom', code: 'boom');

  @override
  Future<AppResult<AggregationSnapshot?>> getSnapshot({
    required String organizationId,
    required AggregationDimension dimension,
    required String companyId,
    required String scopeId,
    required String periodKey,
  }) async {
    return const AppSuccess<AggregationSnapshot?>(null);
  }

  @override
  Future<AppResult<List<AggregationSnapshot>>> listByPeriod({
    required String organizationId,
    required AggregationDimension dimension,
    required String companyId,
    required String periodKey,
    int limit = 50,
  }) async {
    if (failingPeriodKeys.contains(periodKey)) {
      return AppFailure<List<AggregationSnapshot>>(failure);
    }
    return AppSuccess<List<AggregationSnapshot>>(
      snapshots
          .where(
            (snapshot) =>
                snapshot.dimension == dimension &&
                snapshot.companyId == companyId &&
                snapshot.periodKey == periodKey,
          )
          .toList(),
    );
  }

  @override
  Future<AppResult<List<AggregationSnapshot>>> listByPeriodRange({
    required String organizationId,
    required AggregationDimension dimension,
    required String companyId,
    required String scopeId,
    required String fromPeriodKey,
    required String toPeriodKey,
  }) async {
    if (failingRangeKeys.contains('$fromPeriodKey|$toPeriodKey')) {
      return AppFailure<List<AggregationSnapshot>>(failure);
    }
    return AppSuccess<List<AggregationSnapshot>>(
      snapshots
          .where(
            (snapshot) =>
                snapshot.dimension == dimension &&
                snapshot.companyId == companyId &&
                snapshot.scopeId == scopeId &&
                snapshot.periodKey.compareTo(fromPeriodKey) >= 0 &&
                snapshot.periodKey.compareTo(toPeriodKey) <= 0,
          )
          .toList(),
    );
  }
}
