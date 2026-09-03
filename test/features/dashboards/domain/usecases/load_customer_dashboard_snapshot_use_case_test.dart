import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/dashboards/dashboards.dart';
import 'package:vestipro/features/targets/domain/entities/positivacao_snapshot.dart';
import 'package:vestipro/features/targets/domain/repositories/positivacao_repository.dart';
import 'package:vestipro/features/targets/domain/value_objects/positivacao_dimension_type.dart';

void main() {
  late _FakeAggregationRepository aggregationRepository;
  late _FakePositivacaoRepository positivacaoRepository;
  late LoadCustomerDashboardSnapshotUseCase useCase;

  const organizationId = 'org-1';
  const companyId = 'company-1';
  const filters = CustomerDashboardFilters(
    companyId: companyId,
    year: 2026,
    month: 8,
  );

  setUp(() {
    aggregationRepository = _FakeAggregationRepository();
    positivacaoRepository = _FakePositivacaoRepository();
    useCase = LoadCustomerDashboardSnapshotUseCase(
      aggregationRepository,
      positivacaoRepository,
    );
  });

  AggregationSnapshot customerMonthlySnapshot({
    required String customerId,
    required String periodKey,
    required int orderCount,
    double revenueNet = 100,
  }) {
    return AggregationSnapshot(
      organizationId: organizationId,
      companyId: companyId,
      dimension: AggregationDimension.customerMonthly,
      scopeId: customerId,
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
      expect(result, isA<AppFailure<CustomerDashboardSnapshot>>());
    });

    test('returns a validation failure for a blank companyId', () async {
      final result = await useCase(
        organizationId: organizationId,
        filters: const CustomerDashboardFilters(
          companyId: '',
          year: 2026,
          month: 8,
        ),
      );
      expect(result, isA<AppFailure<CustomerDashboardSnapshot>>());
    });
  });

  group('clientes novos e reativados', () {
    test('are always not calculated — no data source distinguishes first '
        'purchase from a returning customer', () async {
      final result = await useCase(
        organizationId: organizationId,
        filters: filters,
      );
      final snapshot = (result as AppSuccess<CustomerDashboardSnapshot>).value;
      expect(
        snapshot.newCustomers.status,
        ExecutiveDashboardMetricStatus.notCalculated,
      );
      expect(
        snapshot.reactivatedCustomers.status,
        ExecutiveDashboardMetricStatus.notCalculated,
      );
    });
  });

  group('positivação-sourced KPIs', () {
    test('clientes ativos/cobertura de carteira/positivação come from '
        'PositivacaoSnapshot, with MoM comparison — same source the Executive '
        'Dashboard uses, never a client-side recalculation', () async {
      positivacaoRepository.seed(
        dimensionType: PositivacaoDimensionType.company,
        dimensionId: companyId,
        periodStart: filters.periodStart,
        snapshot: PositivacaoSnapshot(
          organizationId: organizationId,
          companyId: companyId,
          dimensionType: PositivacaoDimensionType.company,
          dimensionId: companyId,
          periodStart: filters.periodStart,
          periodEnd: filters.periodEnd,
          totalPortfolio: 100,
          positivatedCount: 40,
          calculatedAt: DateTime.utc(2026, 8, 31),
        ),
      );
      positivacaoRepository.seed(
        dimensionType: PositivacaoDimensionType.company,
        dimensionId: companyId,
        periodStart: filters.previousMonth.periodStart,
        snapshot: PositivacaoSnapshot(
          organizationId: organizationId,
          companyId: companyId,
          dimensionType: PositivacaoDimensionType.company,
          dimensionId: companyId,
          periodStart: filters.previousMonth.periodStart,
          periodEnd: filters.previousMonth.periodEnd,
          totalPortfolio: 90,
          positivatedCount: 30,
          calculatedAt: DateTime.utc(2026, 7, 31),
        ),
      );

      final result = await useCase(
        organizationId: organizationId,
        filters: filters,
      );
      final snapshot = (result as AppSuccess<CustomerDashboardSnapshot>).value;
      expect(snapshot.activeCustomers.value, 40);
      expect(snapshot.activeCustomers.previousValue, 30);
      expect(snapshot.portfolioCoverage.value, 100);
      expect(snapshot.positivacaoPercentage.value, 40);
    });

    test('resolve to not calculated when no aggregation pipeline has '
        'populated positivação yet', () async {
      final result = await useCase(
        organizationId: organizationId,
        filters: filters,
      );
      final snapshot = (result as AppSuccess<CustomerDashboardSnapshot>).value;
      expect(
        snapshot.activeCustomers.status,
        ExecutiveDashboardMetricStatus.notCalculated,
      );
    });
  });

  group(
    'taxa de recompra e frequência média — derived from customerMonthly',
    () {
      test(
        'repurchase rate is repeatCustomers/activeCustomers and frequency is '
        'totalOrders/activeCustomers, entirely from the already-fetched '
        'pre-computed snapshots',
        () async {
          aggregationRepository.snapshots.addAll(<AggregationSnapshot>[
            customerMonthlySnapshot(
              customerId: 'customer-a',
              periodKey: '2026-08',
              orderCount: 1,
            ),
            customerMonthlySnapshot(
              customerId: 'customer-b',
              periodKey: '2026-08',
              orderCount: 2,
            ),
            customerMonthlySnapshot(
              customerId: 'customer-c',
              periodKey: '2026-08',
              orderCount: 3,
            ),
          ]);

          final result = await useCase(
            organizationId: organizationId,
            filters: filters,
          );
          final snapshot =
              (result as AppSuccess<CustomerDashboardSnapshot>).value;
          // 2 of 3 customers (b, c) bought more than once this period.
          expect(snapshot.repurchaseRatePercentage.value, closeTo(66.67, 0.01));
          // (1 + 2 + 3) / 3 = 2.
          expect(snapshot.averagePurchaseFrequency.value, 2);
        },
      );

      test('resolve to zero (never a divide-by-zero) when no customer bought '
          'in the period', () async {
        final result = await useCase(
          organizationId: organizationId,
          filters: filters,
        );
        final snapshot =
            (result as AppSuccess<CustomerDashboardSnapshot>).value;
        expect(snapshot.repurchaseRatePercentage.value, 0);
        expect(snapshot.averagePurchaseFrequency.value, 0);
      });

      test('a failure fetching the current period fails these three metrics '
          'without failing the whole snapshot (positivação KPIs still '
          'resolve)', () async {
        positivacaoRepository.seed(
          dimensionType: PositivacaoDimensionType.company,
          dimensionId: companyId,
          periodStart: filters.periodStart,
          snapshot: PositivacaoSnapshot(
            organizationId: organizationId,
            companyId: companyId,
            dimensionType: PositivacaoDimensionType.company,
            dimensionId: companyId,
            periodStart: filters.periodStart,
            periodEnd: filters.periodEnd,
            totalPortfolio: 10,
            positivatedCount: 5,
            calculatedAt: DateTime.utc(2026, 8, 31),
          ),
        );
        aggregationRepository.failingPeriodKeys.add('2026-08');

        final result = await useCase(
          organizationId: organizationId,
          filters: filters,
        );
        final snapshot =
            (result as AppSuccess<CustomerDashboardSnapshot>).value;
        expect(
          snapshot.repurchaseRatePercentage.status,
          ExecutiveDashboardMetricStatus.failed,
        );
        expect(
          snapshot.averagePurchaseFrequency.status,
          ExecutiveDashboardMetricStatus.failed,
        );
        expect(
          snapshot.churnPercentage.status,
          ExecutiveDashboardMetricStatus.failed,
        );
        expect(snapshot.activeCustomers.value, 5);
      });
    },
  );

  group('churn — period-over-period presence in customerMonthly', () {
    test('churned customers are those present last period and absent this '
        'period, divided by last period\'s total', () async {
      aggregationRepository.snapshots.addAll(<AggregationSnapshot>[
        customerMonthlySnapshot(
          customerId: 'customer-a',
          periodKey: '2026-07',
          orderCount: 1,
        ),
        customerMonthlySnapshot(
          customerId: 'customer-b',
          periodKey: '2026-07',
          orderCount: 1,
        ),
        customerMonthlySnapshot(
          customerId: 'customer-c',
          periodKey: '2026-07',
          orderCount: 1,
        ),
        customerMonthlySnapshot(
          customerId: 'customer-a',
          periodKey: '2026-08',
          orderCount: 1,
        ),
        customerMonthlySnapshot(
          customerId: 'customer-b',
          periodKey: '2026-08',
          orderCount: 1,
        ),
      ]);

      final result = await useCase(
        organizationId: organizationId,
        filters: filters,
      );
      final snapshot = (result as AppSuccess<CustomerDashboardSnapshot>).value;
      // customer-c churned: 1 of 3 previous-period customers.
      expect(snapshot.churnPercentage.value, closeTo(33.33, 0.01));
    });

    test('resolves to not calculated when there is no previous period data '
        'to compare against (nothing to churn from)', () async {
      final result = await useCase(
        organizationId: organizationId,
        filters: filters,
      );
      final snapshot = (result as AppSuccess<CustomerDashboardSnapshot>).value;
      expect(
        snapshot.churnPercentage.status,
        ExecutiveDashboardMetricStatus.notCalculated,
      );
    });
  });

  group('team filter narrows positivação-sourced KPIs, never the customer- '
      'derived ones', () {
    test('positivação reads use PositivacaoDimensionType.team when teamId is '
        'set', () async {
      positivacaoRepository.seed(
        dimensionType: PositivacaoDimensionType.team,
        dimensionId: 'team-1',
        periodStart: filters.periodStart,
        snapshot: PositivacaoSnapshot(
          organizationId: organizationId,
          companyId: companyId,
          dimensionType: PositivacaoDimensionType.team,
          dimensionId: 'team-1',
          periodStart: filters.periodStart,
          periodEnd: filters.periodEnd,
          totalPortfolio: 20,
          positivatedCount: 8,
          calculatedAt: DateTime.utc(2026, 8, 31),
        ),
      );

      final result = await useCase(
        organizationId: organizationId,
        filters: filters.copyWith(teamId: 'team-1'),
      );
      final snapshot = (result as AppSuccess<CustomerDashboardSnapshot>).value;
      expect(snapshot.activeCustomers.value, 8);
    });
  });
}

final class _FakeAggregationRepository implements AggregationRepository {
  final List<AggregationSnapshot> snapshots = <AggregationSnapshot>[];
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
    return const AppSuccess<List<AggregationSnapshot>>(<AggregationSnapshot>[]);
  }
}

final class _FakePositivacaoRepository implements PositivacaoRepository {
  final Map<String, PositivacaoSnapshot> _snapshots =
      <String, PositivacaoSnapshot>{};

  void seed({
    required PositivacaoDimensionType dimensionType,
    required String dimensionId,
    required DateTime periodStart,
    required PositivacaoSnapshot snapshot,
  }) {
    _snapshots['${dimensionType.name}|$dimensionId|${periodStart.toIso8601String()}'] =
        snapshot;
  }

  @override
  Future<AppResult<PositivacaoSnapshot>> getForDimension({
    required String organizationId,
    required String companyId,
    required PositivacaoDimensionType dimensionType,
    required String dimensionId,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final key =
        '${dimensionType.name}|$dimensionId|${periodStart.toIso8601String()}';
    return AppSuccess<PositivacaoSnapshot>(
      _snapshots[key] ??
          PositivacaoSnapshot.notCalculated(
            organizationId: organizationId,
            companyId: companyId,
            dimensionType: dimensionType,
            dimensionId: dimensionId,
            periodStart: periodStart,
            periodEnd: periodEnd,
          ),
    );
  }

  @override
  Stream<PositivacaoSnapshot> watchForDimension({
    required String organizationId,
    required String companyId,
    required PositivacaoDimensionType dimensionType,
    required String dimensionId,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    throw UnimplementedError(
      'Not used by LoadCustomerDashboardSnapshotUseCase.',
    );
  }
}
