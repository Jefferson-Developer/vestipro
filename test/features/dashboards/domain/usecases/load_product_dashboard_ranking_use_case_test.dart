import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/dashboards/dashboards.dart';
import 'package:vestipro/features/pricing/domain/entities/price_list.dart';
import 'package:vestipro/features/pricing/domain/entities/price_list_item.dart';
import 'package:vestipro/features/pricing/domain/repositories/price_list_item_repository.dart';
import 'package:vestipro/features/pricing/domain/repositories/price_list_repository.dart';
import 'package:vestipro/features/pricing/domain/usecases/resolve_applicable_price_lists_use_case.dart';
import 'package:vestipro/features/pricing/domain/value_objects/price_list_scope_type.dart';
import 'package:vestipro/features/pricing/domain/value_objects/price_list_status.dart';
import 'package:vestipro/features/pricing/domain/value_objects/price_list_sync_status.dart';

void main() {
  late _FakeAggregationRepository aggregationRepository;
  late _FakePriceListRepository priceListRepository;
  late _FakePriceListItemRepository priceListItemRepository;
  late LoadProductDashboardRankingUseCase useCase;

  const organizationId = 'org-1';
  const companyId = 'company-1';
  const filters = ProductDashboardFilters(
    companyId: companyId,
    year: 2026,
    month: 8,
  );

  setUp(() {
    aggregationRepository = _FakeAggregationRepository();
    priceListRepository = _FakePriceListRepository();
    priceListItemRepository = _FakePriceListItemRepository();
    useCase = LoadProductDashboardRankingUseCase(
      aggregationRepository,
      ResolveApplicablePriceListsUseCase(priceListRepository),
      priceListItemRepository,
    );
  });

  AggregationSnapshot productSnapshot({
    required String productId,
    required String productName,
    String? categoryId,
    String? categoryName,
    String? collectionId,
    required int quantity,
    required double revenueGross,
    required double revenueNet,
    double discountAmount = 0,
    int orderCount = 1,
  }) {
    return AggregationSnapshot(
      organizationId: organizationId,
      companyId: companyId,
      dimension: AggregationDimension.productMonthly,
      scopeId: productId,
      periodKey: '2026-08',
      revenueGross: revenueGross,
      revenueNet: revenueNet,
      discountAmount: discountAmount,
      orderCount: orderCount,
      itemQuantity: quantity,
      labels: <String, String>{
        'productName': productName,
        if (categoryId != null) 'categoryId': categoryId,
        if (categoryName != null) 'categoryName': categoryName,
        if (collectionId != null) 'collectionId': collectionId,
      },
      generatedAt: DateTime.utc(2026, 8, 1),
      version: 1,
    );
  }

  group('validation', () {
    test('returns a validation failure for a blank organizationId', () async {
      final result = await useCase(organizationId: '', filters: filters);
      expect(result, isA<AppFailure<List<ProductDashboardRankingRow>>>());
    });

    test('returns a validation failure for a blank companyId', () async {
      final result = await useCase(
        organizationId: organizationId,
        filters: const ProductDashboardFilters(
          companyId: '',
          year: 2026,
          month: 8,
        ),
      );
      expect(result, isA<AppFailure<List<ProductDashboardRankingRow>>>());
    });
  });

  test(
    'maps aggregation snapshots into ranking rows with discount and mix',
    () async {
      aggregationRepository.snapshots.addAll(<AggregationSnapshot>[
        productSnapshot(
          productId: 'product-a',
          productName: 'Vestido Floral',
          quantity: 10,
          revenueGross: 1000,
          revenueNet: 900,
          discountAmount: 100,
        ),
        productSnapshot(
          productId: 'product-b',
          productName: 'Camisa Linho',
          quantity: 5,
          revenueGross: 100,
          revenueNet: 100,
        ),
      ]);

      final result = await useCase(
        organizationId: organizationId,
        filters: filters,
      );
      final rows =
          (result as AppSuccess<List<ProductDashboardRankingRow>>).value;
      expect(rows, hasLength(2));

      final productA = rows.firstWhere((row) => row.productId == 'product-a');
      expect(productA.discountPercentage, closeTo(10, 0.001));
      expect(productA.mixPercentage, closeTo(90, 0.001));

      final productB = rows.firstWhere((row) => row.productId == 'product-b');
      expect(productB.mixPercentage, closeTo(10, 0.001));
      expect(productB.discountPercentage, 0);
    },
  );

  test(
    'falls back to the productId when no productName label was denormalized',
    () async {
      aggregationRepository.snapshots.add(
        AggregationSnapshot(
          organizationId: organizationId,
          companyId: companyId,
          dimension: AggregationDimension.productMonthly,
          scopeId: 'product-x',
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
          (result as AppSuccess<List<ProductDashboardRankingRow>>).value;
      expect(rows.single.productName, 'product-x');
      expect(rows.single.conversionRate, isNull);
    },
  );

  group('filtros por coleção/categoria', () {
    setUp(() {
      aggregationRepository.snapshots.addAll(<AggregationSnapshot>[
        productSnapshot(
          productId: 'product-a',
          productName: 'Vestido Floral',
          categoryId: 'cat-vestidos',
          categoryName: 'Vestidos',
          collectionId: 'col-verao',
          quantity: 10,
          revenueGross: 1000,
          revenueNet: 1000,
        ),
        productSnapshot(
          productId: 'product-b',
          productName: 'Camisa Linho',
          categoryId: 'cat-camisas',
          categoryName: 'Camisas',
          collectionId: 'col-inverno',
          quantity: 5,
          revenueGross: 500,
          revenueNet: 500,
        ),
      ]);
    });

    test('narrows rows by categoryId', () async {
      final result = await useCase(
        organizationId: organizationId,
        filters: filters.copyWith(categoryId: 'cat-vestidos'),
      );
      final rows =
          (result as AppSuccess<List<ProductDashboardRankingRow>>).value;
      expect(rows.map((row) => row.productId), <String>['product-a']);
    });

    test('narrows rows by collectionId', () async {
      final result = await useCase(
        organizationId: organizationId,
        filters: filters.copyWith(collectionId: 'col-inverno'),
      );
      final rows =
          (result as AppSuccess<List<ProductDashboardRankingRow>>).value;
      expect(rows.map((row) => row.productId), <String>['product-b']);
    });

    test('mix percentage stays relative to the whole filtered set even after '
        'a category filter narrows the visible rows', () async {
      final result = await useCase(
        organizationId: organizationId,
        filters: filters.copyWith(categoryId: 'cat-vestidos'),
      );
      final rows =
          (result as AppSuccess<List<ProductDashboardRankingRow>>).value;
      // product-a is 1000 of a 1500 total (product-a + product-b), so its
      // mix stays ~66.7% even though product-b was filtered out of the
      // returned rows.
      expect(rows.single.mixPercentage, closeTo(66.666, 0.01));
    });
  });

  group('ordenação', () {
    setUp(() {
      aggregationRepository.snapshots.addAll(<AggregationSnapshot>[
        productSnapshot(
          productId: 'product-a',
          productName: 'Vestido Floral',
          quantity: 20,
          revenueGross: 200,
          revenueNet: 200,
        ),
        productSnapshot(
          productId: 'product-b',
          productName: 'Camisa Linho',
          quantity: 5,
          revenueGross: 900,
          revenueNet: 900,
        ),
      ]);
    });

    test('sorts by quantitySold descending by default', () async {
      final result = await useCase(
        organizationId: organizationId,
        filters: filters,
      );
      final rows =
          (result as AppSuccess<List<ProductDashboardRankingRow>>).value;
      expect(rows.map((row) => row.productId), <String>[
        'product-a',
        'product-b',
      ]);
    });

    test('sorts by revenue when requested', () async {
      final result = await useCase(
        organizationId: organizationId,
        filters: filters.copyWith(sortField: ProductDashboardSortField.revenue),
      );
      final rows =
          (result as AppSuccess<List<ProductDashboardRankingRow>>).value;
      expect(rows.map((row) => row.productId), <String>[
        'product-b',
        'product-a',
      ]);
    });
  });

  test(
    'returns an empty list when the period has no aggregation data',
    () async {
      final result = await useCase(
        organizationId: organizationId,
        filters: filters,
      );
      final rows =
          (result as AppSuccess<List<ProductDashboardRankingRow>>).value;
      expect(rows, isEmpty);
    },
  );

  test('propagates a repository failure', () async {
    aggregationRepository.failing = true;
    final result = await useCase(
      organizationId: organizationId,
      filters: filters,
    );
    expect(result, isA<AppFailure<List<ProductDashboardRankingRow>>>());
  });

  group('restrição por tabela de preço ativa', () {
    setUp(() {
      aggregationRepository.snapshots.addAll(<AggregationSnapshot>[
        productSnapshot(
          productId: 'product-priced',
          productName: 'Produto precificado',
          quantity: 10,
          revenueGross: 100,
          revenueNet: 100,
        ),
        productSnapshot(
          productId: 'product-unpriced',
          productName: 'Produto sem preço vigente',
          quantity: 3,
          revenueGross: 30,
          revenueNet: 30,
        ),
      ]);
    });

    test(
      'excludes products absent from every active, company-wide price list',
      () async {
        priceListRepository.priceLists.add(_activePriceList(id: 'pl-1'));
        priceListItemRepository.itemsByPriceListId['pl-1'] = <PriceListItem>[
          PriceListItem(
            id: 'item-1',
            organizationId: organizationId,
            companyId: companyId,
            priceListId: 'pl-1',
            productId: 'product-priced',
            price: 100,
            updatedAt: DateTime.utc(2026, 1, 1),
            updatedBy: 'seed',
          ),
        ];

        final result = await useCase(
          organizationId: organizationId,
          filters: filters,
        );
        final rows =
            (result as AppSuccess<List<ProductDashboardRankingRow>>).value;
        expect(rows.map((row) => row.productId), <String>['product-priced']);
      },
    );

    test('never zeroes out the ranking when no price list is configured yet '
        '(best-effort restriction)', () async {
      final result = await useCase(
        organizationId: organizationId,
        filters: filters,
      );
      final rows =
          (result as AppSuccess<List<ProductDashboardRankingRow>>).value;
      expect(rows, hasLength(2));
    });

    test('never zeroes out the ranking when the price list read fails '
        '(best-effort restriction)', () async {
      priceListRepository.priceLists.add(_activePriceList(id: 'pl-1'));
      priceListItemRepository.failing = true;

      final result = await useCase(
        organizationId: organizationId,
        filters: filters,
      );
      final rows =
          (result as AppSuccess<List<ProductDashboardRankingRow>>).value;
      expect(rows, hasLength(2));
    });
  });
}

PriceList _activePriceList({required String id}) {
  return PriceList(
    id: id,
    organizationId: 'org-1',
    companyId: 'company-1',
    name: 'Tabela padrão',
    currency: 'BRL',
    validFrom: DateTime.utc(2020, 1, 1),
    status: PriceListStatus.active,
    scope: PriceListScopeType.company,
    createdAt: DateTime.utc(2020, 1, 1),
    createdBy: 'seed',
    updatedAt: DateTime.utc(2020, 1, 1),
    updatedBy: 'seed',
    version: 1,
    syncStatus: PriceListSyncStatus.synced,
  );
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

final class _FakePriceListRepository implements PriceListRepository {
  final List<PriceList> priceLists = <PriceList>[];

  @override
  Future<AppResult<PriceList>> create({required PriceList priceList}) async {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<PriceList>> update({required PriceList priceList}) async {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<PriceList?>> getById({
    required String organizationId,
    required String id,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<List<PriceList>>> listByCompany({
    required String organizationId,
    required String companyId,
  }) async {
    return AppSuccess<List<PriceList>>(
      priceLists
          .where(
            (priceList) =>
                priceList.organizationId == organizationId &&
                priceList.companyId == companyId,
          )
          .toList(),
    );
  }
}

final class _FakePriceListItemRepository implements PriceListItemRepository {
  final Map<String, List<PriceListItem>> itemsByPriceListId =
      <String, List<PriceListItem>>{};
  bool failing = false;

  @override
  Future<AppResult<List<PriceListItem>>> listByPriceList({
    required String organizationId,
    required String companyId,
    required String priceListId,
  }) async {
    if (failing) {
      return const AppFailure<List<PriceListItem>>(
        ServerFailure('boom', code: 'boom'),
      );
    }
    return AppSuccess<List<PriceListItem>>(
      itemsByPriceListId[priceListId] ?? const <PriceListItem>[],
    );
  }

  @override
  Future<AppResult<List<PriceListItem>>> listByProduct({
    required String organizationId,
    required String companyId,
    required String productId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<List<PriceListItem>>> upsertBatch({
    required String organizationId,
    required String companyId,
    required String priceListId,
    required List<PriceListItem> items,
    required bool confirmOverwrite,
  }) async {
    throw UnimplementedError();
  }
}
