import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/dashboards/dashboards.dart';
import 'package:vestipro/features/inventory/domain/entities/stock_turnover_metric_scope.dart';
import 'package:vestipro/features/inventory/domain/entities/stock_turnover_metric_snapshot.dart';
import 'package:vestipro/features/inventory/domain/repositories/stock_turnover_repository.dart';
import 'package:vestipro/features/inventory/domain/usecases/get_stock_turnover_metrics_use_case.dart';
import 'package:vestipro/features/inventory/domain/value_objects/stock_coverage_status.dart';
import 'package:vestipro/features/inventory/domain/value_objects/stock_turnover_scope_type.dart';
import 'package:vestipro/features/products/domain/entities/collection.dart';
import 'package:vestipro/features/products/domain/value_objects/collection_status.dart';

void main() {
  late _FakeAggregationRepository aggregationRepository;
  late _FakeStockTurnoverRepository stockTurnoverRepository;
  late LoadCollectionDashboardEntriesUseCase useCase;

  const organizationId = 'org-1';
  const companyId = 'company-1';

  setUp(() {
    aggregationRepository = _FakeAggregationRepository();
    stockTurnoverRepository = _FakeStockTurnoverRepository();
    useCase = LoadCollectionDashboardEntriesUseCase(
      aggregationRepository,
      GetStockTurnoverMetricsUseCase(stockTurnoverRepository),
    );
  });

  Collection buildCollection({
    required String id,
    required String name,
    DateTime? startDate,
    DateTime? endDate,
    int? year,
    CollectionStatus status = CollectionStatus.active,
  }) {
    return Collection(
      id: id,
      organizationId: organizationId,
      name: name,
      seasonId: 'season-1',
      year: year,
      startDate: startDate,
      endDate: endDate,
      status: status,
      version: 1,
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: 'seed',
      updatedAt: DateTime.utc(2026, 1, 1),
      updatedBy: 'seed',
    );
  }

  AggregationSnapshot productSnapshot({
    required String periodKey,
    required String productId,
    required String collectionId,
    String? categoryId,
    String? categoryName,
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
      periodKey: periodKey,
      revenueGross: revenueGross,
      revenueNet: revenueNet,
      discountAmount: discountAmount,
      orderCount: orderCount,
      itemQuantity: quantity,
      labels: <String, String>{
        'collectionId': collectionId,
        if (categoryId != null) 'categoryId': categoryId,
        if (categoryName != null) 'categoryName': categoryName,
      },
      generatedAt: DateTime.utc(2026, 8, 1),
      version: 1,
    );
  }

  group('validação', () {
    test('retorna falha para organizationId em branco', () async {
      final result = await useCase(
        organizationId: '',
        companyId: companyId,
        collections: <Collection>[buildCollection(id: 'col-1', name: 'x')],
      );
      expect(result, isA<AppFailure<List<CollectionDashboardEntry>>>());
    });

    test('retorna falha para lista de coleções vazia', () async {
      final result = await useCase(
        organizationId: organizationId,
        companyId: companyId,
        collections: const <Collection>[],
      );
      expect(result, isA<AppFailure<List<CollectionDashboardEntry>>>());
    });
  });

  test(
    'agrega faturamento/quantidade/desconto por coleção somando os meses do '
    'seu próprio período, filtrando por collectionId',
    () async {
      final collection = buildCollection(
        id: 'col-verao',
        name: 'Verão 2026',
        startDate: DateTime.utc(2026, 1, 1),
        endDate: DateTime.utc(2026, 2, 28),
        year: 2026,
      );
      aggregationRepository.snapshots.addAll(<AggregationSnapshot>[
        productSnapshot(
          periodKey: '2026-01',
          productId: 'product-a',
          collectionId: 'col-verao',
          categoryId: 'cat-vestidos',
          categoryName: 'Vestidos',
          quantity: 10,
          revenueGross: 1000,
          revenueNet: 900,
          discountAmount: 100,
        ),
        productSnapshot(
          periodKey: '2026-02',
          productId: 'product-b',
          collectionId: 'col-verao',
          categoryId: 'cat-camisas',
          categoryName: 'Camisas',
          quantity: 5,
          revenueGross: 500,
          revenueNet: 500,
        ),
        // Different coleção, must never be summed into col-verao's entry.
        productSnapshot(
          periodKey: '2026-01',
          productId: 'product-c',
          collectionId: 'col-inverno',
          quantity: 99,
          revenueGross: 9999,
          revenueNet: 9999,
        ),
      ]);

      final result = await useCase(
        organizationId: organizationId,
        companyId: companyId,
        collections: <Collection>[collection],
      );
      final entries =
          (result as AppSuccess<List<CollectionDashboardEntry>>).value;
      expect(entries, hasLength(1));
      final entry = entries.single;

      expect(entry.hasDefinedPeriod, isTrue);
      expect(entry.revenueGross, 1500);
      expect(entry.revenueNet, 1400);
      expect(entry.quantitySold, 15);
      expect(entry.orderCount, 2);
      expect(entry.discountAmount, 100);
      expect(entry.hasSalesData, isTrue);

      // Mix médio de categorias soma ~100% e nunca inclui a outra coleção.
      final totalMixPercentage = entry.categoryMix.fold<double>(
        0,
        (sum, mix) => sum + mix.percentage,
      );
      expect(totalMixPercentage, closeTo(100, 0.001));
      expect(
        entry.categoryMix.map((mix) => mix.categoryName),
        containsAll(<String>['Vestidos', 'Camisas']),
      );
    },
  );

  test(
    'compara duas ou mais coleções, cada uma sobre o seu próprio período',
    () async {
      final summer = buildCollection(
        id: 'col-verao',
        name: 'Verão 2026',
        startDate: DateTime.utc(2026, 1, 1),
        endDate: DateTime.utc(2026, 1, 31),
      );
      final winter = buildCollection(
        id: 'col-inverno',
        name: 'Inverno 2025',
        startDate: DateTime.utc(2025, 6, 1),
        endDate: DateTime.utc(2025, 6, 30),
      );
      aggregationRepository.snapshots.addAll(<AggregationSnapshot>[
        productSnapshot(
          periodKey: '2026-01',
          productId: 'product-a',
          collectionId: 'col-verao',
          quantity: 10,
          revenueGross: 1000,
          revenueNet: 1000,
        ),
        productSnapshot(
          periodKey: '2025-06',
          productId: 'product-b',
          collectionId: 'col-inverno',
          quantity: 4,
          revenueGross: 400,
          revenueNet: 400,
        ),
      ]);

      final result = await useCase(
        organizationId: organizationId,
        companyId: companyId,
        collections: <Collection>[summer, winter],
      );
      final entries =
          (result as AppSuccess<List<CollectionDashboardEntry>>).value;
      expect(entries.map((entry) => entry.collectionId), <String>[
        'col-verao',
        'col-inverno',
      ]);
      expect(entries[0].revenueNet, 1000);
      expect(entries[0].periodStart, DateTime.utc(2026, 1, 1));
      expect(entries[1].revenueNet, 400);
      expect(entries[1].periodStart, DateTime.utc(2025, 6, 1));
    },
  );

  test(
    'coleção sem vendas no período retorna KPIs zerados, nunca uma falha',
    () async {
      final collection = buildCollection(
        id: 'col-sem-vendas',
        name: 'Outono 2026',
        startDate: DateTime.utc(2026, 3, 1),
        endDate: DateTime.utc(2026, 3, 31),
      );

      final result = await useCase(
        organizationId: organizationId,
        companyId: companyId,
        collections: <Collection>[collection],
      );
      final entry = (result as AppSuccess<List<CollectionDashboardEntry>>)
          .value
          .single;
      expect(entry.hasSalesData, isFalse);
      expect(entry.revenueNet, 0);
      expect(entry.quantitySold, 0);
      expect(entry.categoryMix, isEmpty);
    },
  );

  test(
    'coleção sem startDate nunca dispara uma leitura de agregação, e vem '
    'como período não definido',
    () async {
      final collection = buildCollection(id: 'col-sem-data', name: 'Rascunho');

      final result = await useCase(
        organizationId: organizationId,
        companyId: companyId,
        collections: <Collection>[collection],
      );
      final entry = (result as AppSuccess<List<CollectionDashboardEntry>>)
          .value
          .single;
      expect(entry.hasDefinedPeriod, isFalse);
      expect(entry.margin.status, ExecutiveDashboardMetricStatus.notCalculated);
      expect(
        entry.sellThrough.status,
        ExecutiveDashboardMetricStatus.notCalculated,
      );
      expect(aggregationRepository.periodKeysQueried, isEmpty);
    },
  );

  group('sell-through (TASK-090/TASK-094)', () {
    final collection = buildCollection(
      id: 'col-verao',
      name: 'Verão 2026',
      startDate: DateTime.utc(2026, 1, 1),
      endDate: DateTime.utc(2026, 1, 31),
    );

    test('reflete o sellThroughRate real quando o snapshot existe', () async {
      stockTurnoverRepository.snapshot = _turnoverSnapshot(
        scopeId: 'col-verao',
        sellThroughRate: 0.42,
      );

      final result = await useCase(
        organizationId: organizationId,
        companyId: companyId,
        collections: <Collection>[collection],
      );
      final entry = (result as AppSuccess<List<CollectionDashboardEntry>>)
          .value
          .single;
      expect(entry.sellThrough.status, ExecutiveDashboardMetricStatus.available);
      expect(entry.sellThrough.value, closeTo(42, 0.001));
    });

    test(
      'fica notCalculated quando não há saldo inicial de estoque '
      '(nenhum snapshot de giro ainda gerado)',
      () async {
        stockTurnoverRepository.snapshot = null;

        final result = await useCase(
          organizationId: organizationId,
          companyId: companyId,
          collections: <Collection>[collection],
        );
        final entry = (result as AppSuccess<List<CollectionDashboardEntry>>)
            .value
            .single;
        expect(
          entry.sellThrough.status,
          ExecutiveDashboardMetricStatus.notCalculated,
        );
      },
    );

    test(
      'fica failed (nunca bloqueia os demais KPIs) quando a leitura de giro '
      'falha',
      () async {
        stockTurnoverRepository.failing = true;
        aggregationRepository.snapshots.add(
          productSnapshot(
            periodKey: '2026-01',
            productId: 'product-a',
            collectionId: 'col-verao',
            quantity: 10,
            revenueGross: 1000,
            revenueNet: 1000,
          ),
        );

        final result = await useCase(
          organizationId: organizationId,
          companyId: companyId,
          collections: <Collection>[collection],
        );
        final entry = (result as AppSuccess<List<CollectionDashboardEntry>>)
            .value
            .single;
        expect(entry.sellThrough.status, ExecutiveDashboardMetricStatus.failed);
        // A falha de giro (secundária) nunca zera o faturamento já lido.
        expect(entry.revenueNet, 1000);
      },
    );

    test('sellThroughRate zero (saldo zerado) nunca vira notCalculated', () async {
      stockTurnoverRepository.snapshot = _turnoverSnapshot(
        scopeId: 'col-verao',
        sellThroughRate: 0,
      );

      final result = await useCase(
        organizationId: organizationId,
        companyId: companyId,
        collections: <Collection>[collection],
      );
      final entry = (result as AppSuccess<List<CollectionDashboardEntry>>)
          .value
          .single;
      expect(entry.sellThrough.status, ExecutiveDashboardMetricStatus.available);
      expect(entry.sellThrough.value, 0);
    });
  });

  test('propaga falha do repositório de agregação', () async {
    final collection = buildCollection(
      id: 'col-verao',
      name: 'Verão 2026',
      startDate: DateTime.utc(2026, 1, 1),
      endDate: DateTime.utc(2026, 1, 31),
    );
    aggregationRepository.failing = true;

    final result = await useCase(
      organizationId: organizationId,
      companyId: companyId,
      collections: <Collection>[collection],
    );
    expect(result, isA<AppFailure<List<CollectionDashboardEntry>>>());
  });
}

StockTurnoverMetricSnapshot _turnoverSnapshot({
  required String scopeId,
  required double sellThroughRate,
}) {
  return StockTurnoverMetricSnapshot(
    organizationId: 'org-1',
    scopeType: StockTurnoverScopeType.collection,
    scopeId: scopeId,
    periodStart: DateTime.utc(2026, 1, 1),
    periodEnd: DateTime.utc(2026, 1, 31),
    coveredDays: 30,
    sellThroughRate: sellThroughRate,
    stockCoverageDays: 10,
    turnoverRate: 1.2,
    openingStockQuantity: 100,
    receivedQuantity: 0,
    soldQuantity: 42,
    closingStockQuantity: 58,
    averageStockQuantity: 79,
    averageDailySalesQuantity: 1.4,
    coverageStatus: StockCoverageStatus.ready,
    generatedAt: DateTime.utc(2026, 2, 1),
  );
}

final class _FakeAggregationRepository implements AggregationRepository {
  final List<AggregationSnapshot> snapshots = <AggregationSnapshot>[];
  final List<String> periodKeysQueried = <String>[];
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
    periodKeysQueried.add(periodKey);
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

final class _FakeStockTurnoverRepository implements StockTurnoverRepository {
  StockTurnoverMetricSnapshot? snapshot;
  bool failing = false;

  @override
  Future<AppResult<StockTurnoverMetricSnapshot?>> getByScopeAndPeriod({
    required String organizationId,
    required StockTurnoverMetricScope scope,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    if (failing) {
      return const AppFailure<StockTurnoverMetricSnapshot?>(
        ServerFailure('boom', code: 'boom'),
      );
    }
    return AppSuccess<StockTurnoverMetricSnapshot?>(snapshot);
  }
}
