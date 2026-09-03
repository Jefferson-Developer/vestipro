import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/dashboards/dashboards.dart';
import 'package:vestipro/features/targets/targets.dart';

void main() {
  late _FakeAggregationRepository aggregationRepository;
  late _FakePositivacaoRepository positivacaoRepository;
  late _InMemoryTargetRepository targetRepository;
  late _FakeTargetAchievementRepository targetAchievementRepository;
  late LoadExecutiveDashboardSnapshotUseCase useCase;

  const organizationId = 'org-1';
  const companyId = 'company-1';
  const filters = ExecutiveDashboardFilters(
    companyId: companyId,
    year: 2026,
    month: 8,
  );

  setUp(() {
    aggregationRepository = _FakeAggregationRepository();
    positivacaoRepository = _FakePositivacaoRepository();
    targetRepository = _InMemoryTargetRepository();
    targetAchievementRepository = _FakeTargetAchievementRepository();
    useCase = LoadExecutiveDashboardSnapshotUseCase(
      aggregationRepository,
      positivacaoRepository,
      targetRepository,
      targetAchievementRepository,
    );
  });

  AggregationSnapshot salesDailySnapshot({
    required String periodKey,
    required double revenueNet,
    required int orderCount,
  }) {
    return AggregationSnapshot(
      organizationId: organizationId,
      companyId: companyId,
      dimension: AggregationDimension.salesDaily,
      scopeId: companyId,
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

      expect(result, isA<AppFailure<ExecutiveDashboardSnapshot>>());
    });

    test('returns a validation failure for a blank companyId', () async {
      final result = await useCase(
        organizationId: organizationId,
        filters: const ExecutiveDashboardFilters(
          companyId: '',
          year: 2026,
          month: 8,
        ),
      );

      expect(result, isA<AppFailure<ExecutiveDashboardSnapshot>>());
    });
  });

  group('empty period (no data yet)', () {
    test('revenue/orders/averageTicket resolve to an available zero, growth '
        'and positivação/meta resolve to not calculated', () async {
      final result = await useCase(
        organizationId: organizationId,
        filters: filters,
      );

      final snapshot = (result as AppSuccess<ExecutiveDashboardSnapshot>).value;
      expect(snapshot.revenue.isAvailable, isTrue);
      expect(snapshot.revenue.value, 0);
      expect(snapshot.orders.value, 0);
      expect(snapshot.averageTicket.value, 0);
      expect(
        snapshot.revenueGrowthMoM.status,
        ExecutiveDashboardMetricStatus.notCalculated,
      );
      expect(
        snapshot.revenueGrowthYoY.status,
        ExecutiveDashboardMetricStatus.notCalculated,
      );
      expect(
        snapshot.positivacaoPercentage.status,
        ExecutiveDashboardMetricStatus.notCalculated,
      );
      expect(
        snapshot.targetAchievementPercentage.status,
        ExecutiveDashboardMetricStatus.notCalculated,
      );
      expect(
        snapshot.newCustomers.status,
        ExecutiveDashboardMetricStatus.notCalculated,
      );
      expect(snapshot.revenueTrend, isEmpty);
    });
  });

  group('company-wide (no team filter), full data', () {
    setUp(() {
      aggregationRepository.snapshots.addAll(<AggregationSnapshot>[
        salesDailySnapshot(
          periodKey: '2026-08-01',
          revenueNet: 1000,
          orderCount: 2,
        ),
        salesDailySnapshot(
          periodKey: '2026-08-02',
          revenueNet: 1000,
          orderCount: 2,
        ),
        // Previous month (MoM baseline).
        salesDailySnapshot(
          periodKey: '2026-07-15',
          revenueNet: 1000,
          orderCount: 5,
        ),
        // Same month, previous year (YoY baseline).
        salesDailySnapshot(
          periodKey: '2025-08-15',
          revenueNet: 500,
          orderCount: 5,
        ),
      ]);
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
          totalPortfolio: 200,
          positivatedCount: 80,
          calculatedAt: DateTime.utc(2026, 8, 20),
        ),
      );
      targetRepository.items.add(
        _target(
          id: 'target-1',
          dimensionType: TargetDimensionType.company,
          dimensionId: companyId,
          targetValue: 4000,
          startDate: DateTime.utc(2026, 8, 1),
          endDate: DateTime.utc(2026, 9, 1),
        ),
      );
      targetAchievementRepository.seed(
        'target-1',
        TargetAchievementSnapshot(
          targetId: 'target-1',
          realizedValue: 2000,
          calculatedAt: DateTime.utc(2026, 8, 20),
        ),
      );
    });

    test('sums revenue/orders over the whole month via salesDaily', () async {
      final result = await useCase(
        organizationId: organizationId,
        filters: filters,
      );

      final snapshot = (result as AppSuccess<ExecutiveDashboardSnapshot>).value;
      expect(snapshot.revenue.value, 2000);
      expect(snapshot.orders.value, 4);
      expect(snapshot.averageTicket.value, 500);
    });

    test('computes crescimento MoM/YoY from the comparison periods', () async {
      final result = await useCase(
        organizationId: organizationId,
        filters: filters,
      );

      final snapshot = (result as AppSuccess<ExecutiveDashboardSnapshot>).value;
      // Current 2000 vs previous month 1000 => +100%.
      expect(snapshot.revenueGrowthMoM.value, 100);
      // Current 2000 vs same month last year 500 => +300%.
      expect(snapshot.revenueGrowthYoY.value, 300);
    });

    test('resolves clientes ativos/positivação from the Positivacao '
        'snapshot', () async {
      final result = await useCase(
        organizationId: organizationId,
        filters: filters,
      );

      final snapshot = (result as AppSuccess<ExecutiveDashboardSnapshot>).value;
      expect(snapshot.activeCustomers.value, 80);
      expect(snapshot.positivacaoPercentage.value, 40);
    });

    test('resolves atingimento de meta from the current Target/achievement '
        'snapshot', () async {
      final result = await useCase(
        organizationId: organizationId,
        filters: filters,
      );

      final snapshot = (result as AppSuccess<ExecutiveDashboardSnapshot>).value;
      expect(snapshot.targetAchievementPercentage.value, 50);
    });

    test('revenueTrend carries one point per salesDaily snapshot within the '
        'filtered month', () async {
      final result = await useCase(
        organizationId: organizationId,
        filters: filters,
      );

      final snapshot = (result as AppSuccess<ExecutiveDashboardSnapshot>).value;
      expect(snapshot.revenueTrend, hasLength(2));
      expect(snapshot.revenueTrend.first.value, 1000);
    });
  });

  group('partial failure — um KPI falha e os demais continuam exibidos', () {
    test('a failure summing revenue fails revenue/orders/averageTicket/'
        'growth, but positivação/meta stay available', () async {
      aggregationRepository.failingRangeKeys.add('2026-08-01|2026-08-31');
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
          calculatedAt: DateTime.utc(2026, 8, 20),
        ),
      );

      final result = await useCase(
        organizationId: organizationId,
        filters: filters,
      );

      final snapshot = (result as AppSuccess<ExecutiveDashboardSnapshot>).value;
      expect(snapshot.revenue.status, ExecutiveDashboardMetricStatus.failed);
      expect(snapshot.orders.status, ExecutiveDashboardMetricStatus.failed);
      expect(
        snapshot.averageTicket.status,
        ExecutiveDashboardMetricStatus.failed,
      );
      expect(
        snapshot.revenueGrowthMoM.status,
        ExecutiveDashboardMetricStatus.failed,
      );
      // Positivação came from a different, healthy repository.
      expect(snapshot.positivacaoPercentage.isAvailable, isTrue);
      expect(snapshot.activeCustomers.isAvailable, isTrue);
    });

    test('a failure resolving the Positivacao snapshot fails clientes '
        'ativos/positivação, but revenue stays available', () async {
      aggregationRepository.snapshots.add(
        salesDailySnapshot(
          periodKey: '2026-08-05',
          revenueNet: 900,
          orderCount: 3,
        ),
      );
      positivacaoRepository.failing = true;

      final result = await useCase(
        organizationId: organizationId,
        filters: filters,
      );

      final snapshot = (result as AppSuccess<ExecutiveDashboardSnapshot>).value;
      expect(snapshot.revenue.isAvailable, isTrue);
      expect(
        snapshot.activeCustomers.status,
        ExecutiveDashboardMetricStatus.failed,
      );
      expect(
        snapshot.positivacaoPercentage.status,
        ExecutiveDashboardMetricStatus.failed,
      );
    });

    test('a failure listing Targets fails atingimento de meta, but revenue/'
        'positivação stay available', () async {
      targetRepository.failing = true;
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
          positivatedCount: 4,
          calculatedAt: DateTime.utc(2026, 8, 20),
        ),
      );

      final result = await useCase(
        organizationId: organizationId,
        filters: filters,
      );

      final snapshot = (result as AppSuccess<ExecutiveDashboardSnapshot>).value;
      expect(
        snapshot.targetAchievementPercentage.status,
        ExecutiveDashboardMetricStatus.failed,
      );
      expect(snapshot.positivacaoPercentage.isAvailable, isTrue);
    });

    test('a failure fetching only the previous month degrades the '
        'comparison, without failing the current period value', () async {
      aggregationRepository.snapshots.add(
        salesDailySnapshot(
          periodKey: '2026-08-05',
          revenueNet: 900,
          orderCount: 3,
        ),
      );
      // Previous month range fetch fails; current month range still works.
      aggregationRepository.failingRangeKeys.add('2026-07-01|2026-07-31');

      final result = await useCase(
        organizationId: organizationId,
        filters: filters,
      );

      final snapshot = (result as AppSuccess<ExecutiveDashboardSnapshot>).value;
      expect(snapshot.revenue.isAvailable, isTrue);
      expect(snapshot.revenue.value, 900);
      expect(snapshot.revenue.previousValue, isNull);
      expect(
        snapshot.revenueGrowthMoM.status,
        ExecutiveDashboardMetricStatus.notCalculated,
      );
    });
  });

  group('team filter — sellerMonthly narrowed to the team members', () {
    test(
      'sums only sellerMonthly snapshots of the given teamMemberIds',
      () async {
        aggregationRepository.snapshots.addAll(<AggregationSnapshot>[
          sellerMonthlySnapshot(
            sellerId: 'seller-a',
            periodKey: '2026-08',
            revenueNet: 1000,
            orderCount: 2,
          ),
          sellerMonthlySnapshot(
            sellerId: 'seller-b',
            periodKey: '2026-08',
            revenueNet: 500,
            orderCount: 1,
          ),
          // Not a member of the filtered team — must never be summed in.
          sellerMonthlySnapshot(
            sellerId: 'seller-c',
            periodKey: '2026-08',
            revenueNet: 999999,
            orderCount: 99,
          ),
        ]);
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
            positivatedCount: 12,
            calculatedAt: DateTime.utc(2026, 8, 20),
          ),
        );
        targetRepository.items.add(
          _target(
            id: 'target-team-1',
            dimensionType: TargetDimensionType.team,
            dimensionId: 'team-1',
            targetValue: 3000,
            startDate: DateTime.utc(2026, 8, 1),
            endDate: DateTime.utc(2026, 9, 1),
          ),
        );
        targetAchievementRepository.seed(
          'target-team-1',
          TargetAchievementSnapshot(
            targetId: 'target-team-1',
            realizedValue: 1500,
            calculatedAt: DateTime.utc(2026, 8, 20),
          ),
        );

        final teamFilters = filters.copyWith(teamId: 'team-1');
        final result = await useCase(
          organizationId: organizationId,
          filters: teamFilters,
          teamMemberIds: const <String>['seller-a', 'seller-b'],
        );

        final snapshot =
            (result as AppSuccess<ExecutiveDashboardSnapshot>).value;
        expect(snapshot.revenue.value, 1500);
        expect(snapshot.orders.value, 3);
        expect(snapshot.activeCustomers.value, 12);
        expect(snapshot.positivacaoPercentage.value, 60);
        expect(snapshot.targetAchievementPercentage.value, 50);
      },
    );

    test('an empty team (no members) resolves revenue/orders to zero '
        'without calling the aggregation repository', () async {
      final teamFilters = filters.copyWith(teamId: 'team-empty');

      final result = await useCase(
        organizationId: organizationId,
        filters: teamFilters,
        teamMemberIds: const <String>[],
      );

      final snapshot = (result as AppSuccess<ExecutiveDashboardSnapshot>).value;
      expect(snapshot.revenue.value, 0);
      expect(snapshot.orders.value, 0);
    });
  });
}

Target _target({
  required String id,
  required TargetDimensionType dimensionType,
  required String dimensionId,
  required double targetValue,
  required DateTime startDate,
  required DateTime endDate,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Target(
    id: id,
    organizationId: 'org-1',
    companyId: 'company-1',
    dimensionType: dimensionType,
    dimensionId: dimensionId,
    periodGranularity: TargetPeriodGranularity.monthly,
    startDate: startDate,
    endDate: endDate,
    metricType: TargetMetricType.revenue,
    targetValue: targetValue,
    currency: 'BRL',
    status: TargetStatus.active,
    createdAt: now,
    createdBy: 'manager-1',
    updatedAt: now,
    updatedBy: 'manager-1',
    version: 1,
    syncStatus: TargetSyncStatus.pending,
  );
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

final class _FakePositivacaoRepository implements PositivacaoRepository {
  final Map<String, PositivacaoSnapshot> _snapshots =
      <String, PositivacaoSnapshot>{};
  bool failing = false;

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
    if (failing) {
      return const AppFailure<PositivacaoSnapshot>(
        ServerFailure('boom', code: 'boom'),
      );
    }
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
      'Not used by LoadExecutiveDashboardSnapshotUseCase.',
    );
  }
}

final class _InMemoryTargetRepository implements TargetRepository {
  final List<Target> items = <Target>[];
  bool failing = false;

  @override
  Future<AppResult<Target>> create({required Target target}) async {
    items.add(target);
    return AppSuccess<Target>(target);
  }

  @override
  Future<AppResult<Target>> update({required Target target}) async {
    return AppSuccess<Target>(target);
  }

  @override
  Future<AppResult<Target>> getById({
    required String organizationId,
    required String id,
  }) async {
    return AppSuccess<Target>(items.firstWhere((item) => item.id == id));
  }

  @override
  Future<AppResult<List<Target>>> listByDimension({
    required String organizationId,
    String? companyId,
    required TargetDimensionType dimensionType,
    required String dimensionId,
    TargetMetricType? metricType,
  }) async {
    if (failing) {
      return const AppFailure<List<Target>>(
        ServerFailure('boom', code: 'boom'),
      );
    }
    return AppSuccess<List<Target>>(
      items
          .where(
            (item) =>
                item.dimensionType == dimensionType &&
                item.dimensionId == dimensionId &&
                (metricType == null || item.metricType == metricType),
          )
          .toList(),
    );
  }
}

final class _FakeTargetAchievementRepository
    implements TargetAchievementRepository {
  final Map<String, TargetAchievementSnapshot> _snapshots =
      <String, TargetAchievementSnapshot>{};
  bool failing = false;

  void seed(String targetId, TargetAchievementSnapshot snapshot) {
    _snapshots[targetId] = snapshot;
  }

  @override
  Future<AppResult<TargetAchievementSnapshot>> getForTarget({
    required String organizationId,
    required String targetId,
  }) async {
    if (failing) {
      return const AppFailure<TargetAchievementSnapshot>(
        ServerFailure('boom', code: 'boom'),
      );
    }
    return AppSuccess<TargetAchievementSnapshot>(
      _snapshots[targetId] ?? TargetAchievementSnapshot(targetId: targetId),
    );
  }

  @override
  Stream<TargetAchievementSnapshot> watchForTarget({
    required String organizationId,
    required String targetId,
  }) {
    throw UnimplementedError(
      'Not used by LoadExecutiveDashboardSnapshotUseCase.',
    );
  }
}
