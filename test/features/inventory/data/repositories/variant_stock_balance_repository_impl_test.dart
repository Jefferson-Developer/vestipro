import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/database/database.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/inventory/data/datasources/variant_stock_balance_remote_data_source.dart';
import 'package:vestipro/features/inventory/inventory.dart';

void main() {
  group('VariantStockBalanceRepositoryImpl', () {
    late AppDatabase database;
    late _FakeVariantStockBalanceRemoteDataSource remote;
    late VariantStockBalanceRepositoryImpl repository;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      remote = _FakeVariantStockBalanceRemoteDataSource();
      repository = VariantStockBalanceRepositoryImpl(
        remote,
        database,
        const VariantStockBalanceMapper(),
        const VariantStockBalanceLocalMapper(),
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('uses fresh cache and skips remote re-fetch', () async {
      remote.variantResponses['variant-1'] = <VariantStockBalanceDto>[
        _dto(physicalQuantity: 10),
      ];

      final first = await repository.listByVariantIds(
        organizationId: 'org-1',
        variantIds: const <String>['variant-1'],
      );
      expect(first, isA<AppSuccess<List<VariantStockBalance>>>());
      expect(remote.listByVariantIdsCalls, 1);

      final second = await repository.listByVariantIds(
        organizationId: 'org-1',
        variantIds: const <String>['variant-1'],
      );
      expect(second, isA<AppSuccess<List<VariantStockBalance>>>());
      expect(remote.listByVariantIdsCalls, 1);
    });

    test('refreshes cache when ttl has expired', () async {
      remote.variantResponses['variant-1'] = <VariantStockBalanceDto>[
        _dto(physicalQuantity: 8),
      ];

      final expiredCache = VariantStockBalancesTableCompanion.insert(
        id: 'variant-1_wh-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        productId: 'product-1',
        variantId: 'variant-1',
        warehouseId: 'wh-1',
        physicalQuantity: 3,
        reservedQuantity: 0,
        blockedQuantity: 0,
        updatedAt: DateTime.utc(2026, 8, 26),
        updatedBy: 'owner-1',
        lastSource: 'manual_adjustment',
        version: 1,
        cacheFetchedAt: DateTime.now()
            .toUtc()
            .subtract(VariantStockBalanceRepositoryImpl.cacheTtl)
            .subtract(const Duration(minutes: 1)),
      );
      await database.upsertVariantStockBalances(
        rows: <VariantStockBalancesTableCompanion>[expiredCache],
      );

      final result = await repository.listByVariantIds(
        organizationId: 'org-1',
        variantIds: const <String>['variant-1'],
      );

      expect(result, isA<AppSuccess<List<VariantStockBalance>>>());
      expect(remote.listByVariantIdsCalls, 1);
      final balances = (result as AppSuccess<List<VariantStockBalance>>).value;
      expect(balances.single.physicalQuantity, 8);
    });

    test('forwards pagination parameters on warehouse queries', () async {
      remote.warehouseResponse = <VariantStockBalanceDto>[
        _dto(variantId: 'variant-2', id: 'variant-2_wh-1'),
      ];

      final result = await repository.listByWarehouse(
        organizationId: 'org-1',
        warehouseId: 'wh-1',
        limit: 25,
        startAfterId: 'variant-1',
      );

      expect(result, isA<AppSuccess<List<VariantStockBalance>>>());
      expect(remote.lastWarehouseLimit, 25);
      expect(remote.lastWarehouseCursor, 'variant-1');
    });
  });
}

VariantStockBalanceDto _dto({
  String id = 'variant-1_wh-1',
  String variantId = 'variant-1',
  int physicalQuantity = 12,
}) {
  return VariantStockBalanceDto(
    id: id,
    organizationId: 'org-1',
    companyId: 'company-1',
    productId: 'product-1',
    variantId: variantId,
    warehouseId: 'wh-1',
    physicalQuantity: physicalQuantity,
    reservedQuantity: 2,
    blockedQuantity: 1,
    updatedAt: DateTime.utc(2026, 8, 27),
    updatedBy: 'owner-1',
    lastSource: 'manual_adjustment',
    version: 1,
  );
}

final class _FakeVariantStockBalanceRemoteDataSource
    implements VariantStockBalanceRemoteDataSource {
  final Map<String, List<VariantStockBalanceDto>> variantResponses =
      <String, List<VariantStockBalanceDto>>{};
  List<VariantStockBalanceDto> warehouseResponse =
      const <VariantStockBalanceDto>[];
  int listByVariantIdsCalls = 0;
  int lastWarehouseLimit = 0;
  String? lastWarehouseCursor;

  @override
  Future<List<VariantStockBalanceDto>> listByProductIds({
    required String organizationId,
    required Iterable<String> productIds,
  }) async {
    return variantResponses.values
        .expand((items) => items)
        .toList(growable: false);
  }

  @override
  Future<List<VariantStockBalanceDto>> listByVariantIds({
    required String organizationId,
    required Iterable<String> variantIds,
  }) async {
    listByVariantIdsCalls += 1;
    return variantIds
        .expand(
          (id) => variantResponses[id] ?? const <VariantStockBalanceDto>[],
        )
        .toList(growable: false);
  }

  @override
  Future<List<VariantStockBalanceDto>> listByWarehouse({
    required String organizationId,
    required String warehouseId,
    int limit = 20,
    String? startAfterId,
  }) async {
    lastWarehouseLimit = limit;
    lastWarehouseCursor = startAfterId;
    return warehouseResponse;
  }
}
