import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../../products/domain/entities/variant_availability.dart';
import '../../../products/domain/repositories/product_variant_repository.dart';
import '../../../products/domain/repositories/variant_availability_repository.dart';
import '../../../products/domain/value_objects/variant_availability_status.dart';
import '../../domain/entities/future_stock_entry.dart';
import '../../domain/entities/variant_stock_balance.dart';
import '../../domain/repositories/future_stock_repository.dart';
import '../../domain/repositories/variant_stock_balance_repository.dart';
import '../../domain/value_objects/future_stock_source.dart';

@LazySingleton(as: VariantAvailabilityRepository)
final class InventoryVariantAvailabilityRepository
    implements VariantAvailabilityRepository {
  const InventoryVariantAvailabilityRepository(
    this._balances,
    this._variants,
    this._futureStock,
  );

  final VariantStockBalanceRepository _balances;
  final ProductVariantRepository _variants;
  final FutureStockRepository _futureStock;

  @override
  Future<AppResult<List<VariantAvailability>>> listByProductIds({
    required String organizationId,
    required Iterable<String> productIds,
  }) async {
    final result = await _balances.listByProductIds(
      organizationId: organizationId,
      productIds: productIds,
    );
    final futureEntries = await _futureStock.listByProductIds(
      organizationId: organizationId,
      productIds: productIds,
    );
    return switch (result) {
      AppSuccess<List<VariantStockBalance>>(value: final balances) =>
        AppSuccess<List<VariantAvailability>>(
          await _toAvailabilityList(
            organizationId: organizationId,
            balances: balances,
            futureEntries: futureEntries,
            requestedVariantIds: const <String>{},
          ),
        ),
      AppFailure<List<VariantStockBalance>>(failure: final failure) =>
        AppFailure<List<VariantAvailability>>(failure),
    };
  }

  @override
  Future<AppResult<List<VariantAvailability>>> listByVariantIds({
    required String organizationId,
    required Iterable<String> variantIds,
  }) async {
    final requested = variantIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    final result = await _balances.listByVariantIds(
      organizationId: organizationId,
      variantIds: requested,
    );
    final futureEntries = await _futureStock.listByVariantIds(
      organizationId: organizationId,
      variantIds: requested,
    );
    return switch (result) {
      AppSuccess<List<VariantStockBalance>>(value: final balances) =>
        AppSuccess<List<VariantAvailability>>(
          await _toAvailabilityList(
            organizationId: organizationId,
            balances: balances,
            futureEntries: futureEntries,
            requestedVariantIds: requested,
          ),
        ),
      AppFailure<List<VariantStockBalance>>(failure: final failure) =>
        AppFailure<List<VariantAvailability>>(failure),
    };
  }

  Future<List<VariantAvailability>> _toAvailabilityList({
    required String organizationId,
    required List<VariantStockBalance> balances,
    required List<FutureStockEntry> futureEntries,
    required Set<String> requestedVariantIds,
  }) async {
    final grouped = <String, List<VariantStockBalance>>{};
    for (final balance in balances) {
      grouped
          .putIfAbsent(balance.variantId, () => <VariantStockBalance>[])
          .add(balance);
    }
    final groupedFutureEntries = <String, List<FutureStockEntry>>{};
    for (final entry in futureEntries) {
      groupedFutureEntries
          .putIfAbsent(entry.variantId, () => <FutureStockEntry>[])
          .add(entry);
    }
    for (final items in groupedFutureEntries.values) {
      items.sort(
        (left, right) => left.expectedDate.compareTo(right.expectedDate),
      );
    }

    final ids = requestedVariantIds.isEmpty
        ? <String>{...grouped.keys, ...groupedFutureEntries.keys}
        : requestedVariantIds;
    final availabilities = <VariantAvailability>[];
    for (final variantId in ids) {
      final items = grouped[variantId] ?? const <VariantStockBalance>[];
      final futureItems =
          groupedFutureEntries[variantId] ?? const <FutureStockEntry>[];
      final total = items.fold<int>(
        0,
        (sum, balance) => sum + balance.sellableQuantity,
      );
      final productId = items.isNotEmpty
          ? items.first.productId
          : futureItems.isNotEmpty
          ? futureItems.first.productId
          : await _lookupProductId(
              organizationId: organizationId,
              variantId: variantId,
            );
      final futureTotal = futureItems.fold<int>(
        0,
        (sum, entry) => sum + entry.quantity,
      );
      final nextFuture = futureItems.isEmpty ? null : futureItems.first;
      availabilities.add(
        VariantAvailability(
          variantId: variantId,
          productId: productId,
          status: total > 0
              ? VariantAvailabilityStatus.readyStock
              : nextFuture != null
              ? VariantAvailabilityStatus.futureStock
              : VariantAvailabilityStatus.unavailable,
          availableQuantity: total > 0 ? total : null,
          futureAvailableAt: nextFuture?.expectedDate,
          futureAvailableQuantity: futureTotal > 0 ? futureTotal : null,
          futureSourceLabel: nextFuture?.source.label,
          warehouseQuantities: Map<String, int>.unmodifiable({
            for (final item in items) item.warehouseId: item.sellableQuantity,
          }),
        ),
      );
    }
    return availabilities;
  }

  Future<String> _lookupProductId({
    required String organizationId,
    required String variantId,
  }) async {
    final result = await _variants.getById(
      organizationId: organizationId,
      id: variantId,
    );
    return switch (result) {
      AppSuccess(value: final variant) => variant.productId,
      AppFailure() => 'unknown-product',
    };
  }
}
