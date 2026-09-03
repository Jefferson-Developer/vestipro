import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/dashboards/dashboards.dart';

void main() {
  late _FakeAggregationRepository aggregationRepository;
  late LoadCustomerDashboardRankingUseCase useCase;

  const organizationId = 'org-1';
  const companyId = 'company-1';
  const filters = CustomerDashboardFilters(
    companyId: companyId,
    year: 2026,
    month: 8,
  );

  setUp(() {
    aggregationRepository = _FakeAggregationRepository();
    useCase = LoadCustomerDashboardRankingUseCase(aggregationRepository);
  });

  AggregationSnapshot customerSnapshot({
    required String customerId,
    required String customerName,
    String? segment,
    required double revenueNet,
    required int orderCount,
  }) {
    return AggregationSnapshot(
      organizationId: organizationId,
      companyId: companyId,
      dimension: AggregationDimension.customerMonthly,
      scopeId: customerId,
      periodKey: '2026-08',
      revenueGross: revenueNet,
      revenueNet: revenueNet,
      discountAmount: 0,
      orderCount: orderCount,
      itemQuantity: orderCount,
      labels: <String, String>{
        'customerName': customerName,
        if (segment != null) 'segment': segment,
      },
      generatedAt: DateTime.utc(2026, 8, 1),
      version: 1,
    );
  }

  group('validation', () {
    test('returns a validation failure for a blank organizationId', () async {
      final result = await useCase(organizationId: '', filters: filters);
      expect(result, isA<AppFailure<List<CustomerDashboardRankingRow>>>());
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
      expect(result, isA<AppFailure<List<CustomerDashboardRankingRow>>>());
    });
  });

  test(
    'maps aggregation snapshots into ranking rows with average ticket',
    () async {
      aggregationRepository.snapshots.add(
        customerSnapshot(
          customerId: 'customer-a',
          customerName: 'Loja A',
          revenueNet: 1000,
          orderCount: 4,
        ),
      );

      final result = await useCase(
        organizationId: organizationId,
        filters: filters,
      );
      final rows =
          (result as AppSuccess<List<CustomerDashboardRankingRow>>).value;
      expect(rows, hasLength(1));
      expect(rows.single.customerName, 'Loja A');
      expect(rows.single.averageTicket, 250);
    },
  );

  test('falls back to the customerId when no customerName label was '
      'denormalized', () async {
    aggregationRepository.snapshots.add(
      AggregationSnapshot(
        organizationId: organizationId,
        companyId: companyId,
        dimension: AggregationDimension.customerMonthly,
        scopeId: 'customer-x',
        periodKey: '2026-08',
        revenueGross: 100,
        revenueNet: 100,
        discountAmount: 0,
        orderCount: 1,
        itemQuantity: 1,
        labels: const <String, String>{},
        generatedAt: DateTime.utc(2026, 8, 1),
        version: 1,
      ),
    );

    final result = await useCase(
      organizationId: organizationId,
      filters: filters,
    );
    final rows =
        (result as AppSuccess<List<CustomerDashboardRankingRow>>).value;
    expect(rows.single.customerName, 'customer-x');
  });

  group('segmentação dinâmica', () {
    test('narrows rows by the segment label, case-insensitively', () async {
      aggregationRepository.snapshots.addAll(<AggregationSnapshot>[
        customerSnapshot(
          customerId: 'customer-a',
          customerName: 'Loja A',
          segment: 'Premium',
          revenueNet: 500,
          orderCount: 1,
        ),
        customerSnapshot(
          customerId: 'customer-b',
          customerName: 'Loja B',
          segment: 'basico',
          revenueNet: 300,
          orderCount: 1,
        ),
      ]);

      final result = await useCase(
        organizationId: organizationId,
        filters: filters.copyWith(segment: 'premium'),
      );
      final rows =
          (result as AppSuccess<List<CustomerDashboardRankingRow>>).value;
      expect(rows.map((row) => row.customerId), <String>['customer-a']);
    });
  });

  group('ordenação', () {
    setUp(() {
      aggregationRepository.snapshots.addAll(<AggregationSnapshot>[
        customerSnapshot(
          customerId: 'customer-a',
          customerName: 'Loja A',
          revenueNet: 100,
          orderCount: 5,
        ),
        customerSnapshot(
          customerId: 'customer-b',
          customerName: 'Loja B',
          revenueNet: 500,
          orderCount: 1,
        ),
      ]);
    });

    test('sorts by revenue descending by default', () async {
      final result = await useCase(
        organizationId: organizationId,
        filters: filters,
      );
      final rows =
          (result as AppSuccess<List<CustomerDashboardRankingRow>>).value;
      expect(rows.map((row) => row.customerId), <String>[
        'customer-b',
        'customer-a',
      ]);
    });

    test('sorts by frequency (orderCount) when requested', () async {
      final result = await useCase(
        organizationId: organizationId,
        filters: filters.copyWith(
          sortField: CustomerDashboardSortField.frequency,
        ),
      );
      final rows =
          (result as AppSuccess<List<CustomerDashboardRankingRow>>).value;
      expect(rows.map((row) => row.customerId), <String>[
        'customer-a',
        'customer-b',
      ]);
    });

    test('sorts ascending when sortDescending is false', () async {
      final result = await useCase(
        organizationId: organizationId,
        filters: filters.copyWith(sortDescending: false),
      );
      final rows =
          (result as AppSuccess<List<CustomerDashboardRankingRow>>).value;
      expect(rows.map((row) => row.customerId), <String>[
        'customer-a',
        'customer-b',
      ]);
    });
  });

  test('propagates a repository failure', () async {
    aggregationRepository.failing = true;
    final result = await useCase(
      organizationId: organizationId,
      filters: filters,
    );
    expect(result, isA<AppFailure<List<CustomerDashboardRankingRow>>>());
  });
}

final class _FakeAggregationRepository implements AggregationRepository {
  final List<AggregationSnapshot> snapshots = <AggregationSnapshot>[];
  bool failing = false;
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
    if (failing) {
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
