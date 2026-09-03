import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/dashboards/dashboards.dart';

void main() {
  late _FakeAggregationRepository aggregationRepository;
  late LoadSalesDashboardGroupRowsUseCase useCase;

  const organizationId = 'org-1';
  const companyId = 'company-1';

  setUp(() {
    aggregationRepository = _FakeAggregationRepository();
    useCase = LoadSalesDashboardGroupRowsUseCase(aggregationRepository);
  });

  AggregationSnapshot snapshot({
    required AggregationDimension dimension,
    required String scopeId,
    required String periodKey,
    required double revenueNet,
    int orderCount = 1,
    int itemQuantity = 1,
    double discountAmount = 0,
    Map<String, String> labels = const <String, String>{},
  }) {
    return AggregationSnapshot(
      organizationId: organizationId,
      companyId: companyId,
      dimension: dimension,
      scopeId: scopeId,
      periodKey: periodKey,
      revenueGross: revenueNet + discountAmount,
      revenueNet: revenueNet,
      discountAmount: discountAmount,
      orderCount: orderCount,
      itemQuantity: itemQuantity,
      labels: labels,
      generatedAt: DateTime.utc(2026, 8, 1),
      version: 1,
    );
  }

  group('validation', () {
    test('returns a validation failure for a blank organizationId', () async {
      final result = await useCase(
        organizationId: '',
        filters: const SalesDashboardFilters(
          companyId: companyId,
          year: 2026,
          month: 8,
        ),
      );
      expect(result, isA<AppFailure<List<SalesDashboardGroupRow>>>());
    });
  });

  group('grouping by seller/customer/product', () {
    test(
      'builds one row per scope, labelled from the snapshot\'s '
      'denormalized labels, with the comparison period revenue attached',
      () async {
        aggregationRepository.seed(
          AggregationDimension.sellerMonthly,
          '2026-08',
          <AggregationSnapshot>[
            snapshot(
              dimension: AggregationDimension.sellerMonthly,
              scopeId: 'seller-1',
              periodKey: '2026-08',
              revenueNet: 1000,
              orderCount: 4,
              itemQuantity: 10,
              discountAmount: 50,
              labels: const <String, String>{'sellerName': 'Ana Vendedora'},
            ),
          ],
        );
        aggregationRepository.seed(
          AggregationDimension.sellerMonthly,
          '2026-07',
          <AggregationSnapshot>[
            snapshot(
              dimension: AggregationDimension.sellerMonthly,
              scopeId: 'seller-1',
              periodKey: '2026-07',
              revenueNet: 500,
            ),
          ],
        );

        final result = await useCase(
          organizationId: organizationId,
          filters: const SalesDashboardFilters(
            companyId: companyId,
            year: 2026,
            month: 8,
          ),
        );
        final rows = (result as AppSuccess<List<SalesDashboardGroupRow>>).value;
        expect(rows, hasLength(1));
        expect(rows.single.scopeId, 'seller-1');
        expect(rows.single.label, 'Ana Vendedora');
        expect(rows.single.revenueNet, 1000);
        expect(rows.single.previousRevenueNet, 500);
        expect(rows.single.changePercentage, 100);
        expect(rows.single.changeAbsolute, 500);
      },
    );

    test('a scope with no comparison-period snapshot renders "sem '
        'comparação" (null), never a fabricated -100%', () async {
      aggregationRepository.seed(
        AggregationDimension.customerMonthly,
        '2026-08',
        <AggregationSnapshot>[
          snapshot(
            dimension: AggregationDimension.customerMonthly,
            scopeId: 'customer-new',
            periodKey: '2026-08',
            revenueNet: 400,
          ),
        ],
      );

      final result = await useCase(
        organizationId: organizationId,
        filters: const SalesDashboardFilters(
          companyId: companyId,
          year: 2026,
          month: 8,
          groupDimension: SalesDashboardGroupDimension.customer,
        ),
      );
      final rows = (result as AppSuccess<List<SalesDashboardGroupRow>>).value;
      expect(rows.single.previousRevenueNet, isNull);
      expect(rows.single.changePercentage, isNull);
      expect(rows.single.changeAbsolute, isNull);
    });
  });

  group(
    'grouping by category — client-side re-aggregation of productMonthly',
    () {
      test('sums every product row sharing the same categoryId, and falls '
          'back to "Sem categoria" when none is denormalized', () async {
        aggregationRepository.seed(
          AggregationDimension.productMonthly,
          '2026-08',
          <AggregationSnapshot>[
            snapshot(
              dimension: AggregationDimension.productMonthly,
              scopeId: 'product-1',
              periodKey: '2026-08',
              revenueNet: 300,
              orderCount: 2,
              itemQuantity: 6,
              labels: const <String, String>{
                'categoryId': 'cat-1',
                'categoryName': 'Camisas',
              },
            ),
            snapshot(
              dimension: AggregationDimension.productMonthly,
              scopeId: 'product-2',
              periodKey: '2026-08',
              revenueNet: 200,
              orderCount: 1,
              itemQuantity: 4,
              labels: const <String, String>{
                'categoryId': 'cat-1',
                'categoryName': 'Camisas',
              },
            ),
            snapshot(
              dimension: AggregationDimension.productMonthly,
              scopeId: 'product-3',
              periodKey: '2026-08',
              revenueNet: 50,
              orderCount: 1,
              itemQuantity: 1,
            ),
          ],
        );

        final result = await useCase(
          organizationId: organizationId,
          filters: const SalesDashboardFilters(
            companyId: companyId,
            year: 2026,
            month: 8,
            groupDimension: SalesDashboardGroupDimension.category,
          ),
        );
        final rows = (result as AppSuccess<List<SalesDashboardGroupRow>>).value;
        final camisas = rows.firstWhere((row) => row.scopeId == 'cat-1');
        expect(camisas.label, 'Camisas');
        expect(camisas.revenueNet, 500);
        expect(camisas.orderCount, 3);
        expect(camisas.itemQuantity, 10);

        final uncategorized = rows.firstWhere(
          (row) => row.scopeId == 'uncategorized',
        );
        expect(uncategorized.label, 'Sem categoria');
        expect(uncategorized.revenueNet, 50);
      });
    },
  );

  group('RBAC seller scoping', () {
    test('an empty sellerScopeIds for the seller dimension returns zero rows '
        'without a company-wide fallback', () async {
      aggregationRepository.seed(
        AggregationDimension.sellerMonthly,
        '2026-08',
        <AggregationSnapshot>[
          snapshot(
            dimension: AggregationDimension.sellerMonthly,
            scopeId: 'seller-1',
            periodKey: '2026-08',
            revenueNet: 999,
          ),
        ],
      );

      final result = await useCase(
        organizationId: organizationId,
        filters: const SalesDashboardFilters(
          companyId: companyId,
          year: 2026,
          month: 8,
        ),
        sellerScopeIds: const <String>{},
      );
      final rows = (result as AppSuccess<List<SalesDashboardGroupRow>>).value;
      expect(rows, isEmpty);
      expect(aggregationRepository.callCount, 0);
    });

    test('non-null sellerScopeIds restricts both the current and comparison '
        'rows to that set', () async {
      aggregationRepository.seed(
        AggregationDimension.sellerMonthly,
        '2026-08',
        <AggregationSnapshot>[
          snapshot(
            dimension: AggregationDimension.sellerMonthly,
            scopeId: 'seller-allowed',
            periodKey: '2026-08',
            revenueNet: 100,
          ),
          snapshot(
            dimension: AggregationDimension.sellerMonthly,
            scopeId: 'seller-other',
            periodKey: '2026-08',
            revenueNet: 9999,
          ),
        ],
      );

      final result = await useCase(
        organizationId: organizationId,
        filters: const SalesDashboardFilters(
          companyId: companyId,
          year: 2026,
          month: 8,
        ),
        sellerScopeIds: const <String>{'seller-allowed'},
      );
      final rows = (result as AppSuccess<List<SalesDashboardGroupRow>>).value;
      expect(rows, hasLength(1));
      expect(rows.single.scopeId, 'seller-allowed');
    });

    test('sellerScopeIds never restricts a non-seller dimension', () async {
      aggregationRepository.seed(
        AggregationDimension.customerMonthly,
        '2026-08',
        <AggregationSnapshot>[
          snapshot(
            dimension: AggregationDimension.customerMonthly,
            scopeId: 'customer-1',
            periodKey: '2026-08',
            revenueNet: 100,
          ),
        ],
      );

      final result = await useCase(
        organizationId: organizationId,
        filters: const SalesDashboardFilters(
          companyId: companyId,
          year: 2026,
          month: 8,
          groupDimension: SalesDashboardGroupDimension.customer,
        ),
        sellerScopeIds: const <String>{},
      );
      final rows = (result as AppSuccess<List<SalesDashboardGroupRow>>).value;
      expect(rows, hasLength(1));
    });
  });

  group('sorting', () {
    test('defaults to revenue descending', () async {
      aggregationRepository.seed(
        AggregationDimension.sellerMonthly,
        '2026-08',
        <AggregationSnapshot>[
          snapshot(
            dimension: AggregationDimension.sellerMonthly,
            scopeId: 'low',
            periodKey: '2026-08',
            revenueNet: 100,
          ),
          snapshot(
            dimension: AggregationDimension.sellerMonthly,
            scopeId: 'high',
            periodKey: '2026-08',
            revenueNet: 900,
          ),
        ],
      );

      final result = await useCase(
        organizationId: organizationId,
        filters: const SalesDashboardFilters(
          companyId: companyId,
          year: 2026,
          month: 8,
        ),
      );
      final rows = (result as AppSuccess<List<SalesDashboardGroupRow>>).value;
      expect(rows.map((row) => row.scopeId).toList(), <String>['high', 'low']);
    });

    test(
      'sortField/sortDescending reorders the already-fetched rows',
      () async {
        aggregationRepository.seed(
          AggregationDimension.sellerMonthly,
          '2026-08',
          <AggregationSnapshot>[
            snapshot(
              dimension: AggregationDimension.sellerMonthly,
              scopeId: 'b-seller',
              periodKey: '2026-08',
              revenueNet: 900,
              labels: const <String, String>{'sellerName': 'B Seller'},
            ),
            snapshot(
              dimension: AggregationDimension.sellerMonthly,
              scopeId: 'a-seller',
              periodKey: '2026-08',
              revenueNet: 100,
              labels: const <String, String>{'sellerName': 'A Seller'},
            ),
          ],
        );

        final result = await useCase(
          organizationId: organizationId,
          filters: const SalesDashboardFilters(
            companyId: companyId,
            year: 2026,
            month: 8,
            sortField: SalesDashboardSortField.label,
            sortDescending: false,
          ),
        );
        final rows = (result as AppSuccess<List<SalesDashboardGroupRow>>).value;
        expect(rows.map((row) => row.label).toList(), <String>[
          'A Seller',
          'B Seller',
        ]);
      },
    );
  });

  group('comparison mode', () {
    test(
      'previousYear compares against the same month a year before',
      () async {
        aggregationRepository.seed(
          AggregationDimension.sellerMonthly,
          '2026-08',
          <AggregationSnapshot>[
            snapshot(
              dimension: AggregationDimension.sellerMonthly,
              scopeId: 'seller-1',
              periodKey: '2026-08',
              revenueNet: 200,
            ),
          ],
        );
        aggregationRepository.seed(
          AggregationDimension.sellerMonthly,
          '2025-08',
          <AggregationSnapshot>[
            snapshot(
              dimension: AggregationDimension.sellerMonthly,
              scopeId: 'seller-1',
              periodKey: '2025-08',
              revenueNet: 100,
            ),
          ],
        );

        final result = await useCase(
          organizationId: organizationId,
          filters: const SalesDashboardFilters(
            companyId: companyId,
            year: 2026,
            month: 8,
            comparisonMode: SalesDashboardComparisonMode.previousYear,
          ),
        );
        final rows = (result as AppSuccess<List<SalesDashboardGroupRow>>).value;
        expect(rows.single.previousRevenueNet, 100);
        expect(rows.single.changePercentage, 100);
      },
    );
  });
}

final class _FakeAggregationRepository implements AggregationRepository {
  final Map<String, List<AggregationSnapshot>> _byDimensionAndPeriod =
      <String, List<AggregationSnapshot>>{};
  int callCount = 0;

  void seed(
    AggregationDimension dimension,
    String periodKey,
    List<AggregationSnapshot> snapshots,
  ) {
    _byDimensionAndPeriod['${dimension.name}|$periodKey'] = snapshots;
  }

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
    callCount++;
    return AppSuccess<List<AggregationSnapshot>>(
      _byDimensionAndPeriod['${dimension.name}|$periodKey'] ??
          const <AggregationSnapshot>[],
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
