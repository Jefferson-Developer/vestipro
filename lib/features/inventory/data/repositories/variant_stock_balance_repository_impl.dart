import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/variant_inventory_availability.dart';
import '../../domain/entities/variant_stock_balance.dart';
import '../../domain/repositories/variant_stock_balance_repository.dart';
import '../datasources/variant_stock_balance_remote_data_source.dart';
import '../mappers/variant_stock_balance_local_mapper.dart';
import '../mappers/variant_stock_balance_mapper.dart';

@LazySingleton(as: VariantStockBalanceRepository)
final class VariantStockBalanceRepositoryImpl
    implements VariantStockBalanceRepository {
  VariantStockBalanceRepositoryImpl(
    this._remote,
    this._database,
    this._mapper,
    this._localMapper,
  );

  static const Duration cacheTtl = Duration(minutes: 10);

  final VariantStockBalanceRemoteDataSource _remote;
  final AppDatabase _database;
  final VariantStockBalanceMapper _mapper;
  final VariantStockBalanceLocalMapper _localMapper;

  @override
  Future<AppResult<VariantInventoryAvailability>> getAvailability({
    required String organizationId,
    required String variantId,
    String? warehouseId,
  }) async {
    final result = await listByVariantIds(
      organizationId: organizationId,
      variantIds: <String>[variantId],
    );
    return switch (result) {
      AppSuccess<List<VariantStockBalance>>(value: final balances) =>
        AppSuccess<VariantInventoryAvailability>(
          _aggregateAvailability(
            variantId: variantId,
            balances: warehouseId == null || warehouseId.isEmpty
                ? balances
                : balances
                      .where((balance) => balance.warehouseId == warehouseId)
                      .toList(growable: false),
          ),
        ),
      AppFailure<List<VariantStockBalance>>(failure: final failure) =>
        AppFailure<VariantInventoryAvailability>(failure),
    };
  }

  @override
  Future<AppResult<List<VariantStockBalance>>> listByProductIds({
    required String organizationId,
    required Iterable<String> productIds,
  }) async {
    try {
      final remoteItems = await _remote.listByProductIds(
        organizationId: organizationId,
        productIds: productIds,
      );
      final now = DateTime.now().toUtc();
      final balances = remoteItems
          .map((dto) => _mapper.toEntity(dto, cacheFetchedAt: now))
          .toList(growable: false);
      await _database.upsertVariantStockBalances(
        rows: balances.map(_localMapper.toRow).toList(growable: false),
      );
      return AppSuccess<List<VariantStockBalance>>(balances);
    } on AppException catch (exception) {
      return AppFailure<List<VariantStockBalance>>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<List<VariantStockBalance>>(
        UnexpectedFailure(
          'Unexpected error loading stock balances by product.',
          code: 'variant_stock_balance_product_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<VariantStockBalance>>> listByVariantIds({
    required String organizationId,
    required Iterable<String> variantIds,
  }) async {
    final requested = variantIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (requested.isEmpty) {
      return const AppSuccess<List<VariantStockBalance>>(
        <VariantStockBalance>[],
      );
    }

    try {
      final cached = await _database.getVariantStockBalancesByVariantIds(
        organizationId: organizationId,
        variantIds: requested,
      );
      final cachedBalances = cached
          .map(_localMapper.fromRow)
          .toList(growable: false);
      final now = DateTime.now().toUtc();
      final hasFreshCache =
          cachedBalances.isNotEmpty &&
          requested.every(
            (variantId) => cachedBalances.any(
              (balance) =>
                  balance.variantId == variantId &&
                  now.difference(balance.cacheFetchedAt) < cacheTtl,
            ),
          );
      if (hasFreshCache) {
        return AppSuccess<List<VariantStockBalance>>(cachedBalances);
      }

      final remoteItems = await _remote.listByVariantIds(
        organizationId: organizationId,
        variantIds: requested,
      );
      final balances = remoteItems
          .map((dto) => _mapper.toEntity(dto, cacheFetchedAt: now))
          .toList(growable: false);
      await _database.upsertVariantStockBalances(
        rows: balances.map(_localMapper.toRow).toList(growable: false),
      );
      return AppSuccess<List<VariantStockBalance>>(balances);
    } on AppException catch (exception) {
      return AppFailure<List<VariantStockBalance>>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<List<VariantStockBalance>>(
        UnexpectedFailure(
          'Unexpected error loading stock balances by variant.',
          code: 'variant_stock_balance_variant_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<VariantStockBalance>>> listByWarehouse({
    required String organizationId,
    required String warehouseId,
    int limit = 20,
    String? startAfterId,
  }) async {
    try {
      final items = await _remote.listByWarehouse(
        organizationId: organizationId,
        warehouseId: warehouseId,
        limit: limit,
        startAfterId: startAfterId,
      );
      final now = DateTime.now().toUtc();
      final balances = items
          .map((dto) => _mapper.toEntity(dto, cacheFetchedAt: now))
          .toList(growable: false);
      await _database.upsertVariantStockBalances(
        rows: balances.map(_localMapper.toRow).toList(growable: false),
      );
      return AppSuccess<List<VariantStockBalance>>(balances);
    } on AppException catch (exception) {
      return AppFailure<List<VariantStockBalance>>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<List<VariantStockBalance>>(
        UnexpectedFailure(
          'Unexpected error loading stock balances by warehouse.',
          code: 'variant_stock_balance_warehouse_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  VariantInventoryAvailability _aggregateAvailability({
    required String variantId,
    required List<VariantStockBalance> balances,
  }) {
    final total = balances.fold<int>(
      0,
      (sum, balance) => sum + balance.sellableQuantity,
    );
    return VariantInventoryAvailability(
      variantId: variantId,
      productId: balances.isNotEmpty
          ? balances.first.productId
          : 'unknown-product',
      totalSellableQuantity: total,
      byWarehouse: List<VariantStockBalance>.unmodifiable(balances),
    );
  }
}
