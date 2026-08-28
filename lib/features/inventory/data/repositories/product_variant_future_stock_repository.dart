import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../../products/domain/entities/product_variant.dart';
import '../../../products/domain/repositories/product_variant_repository.dart';
import '../../../products/domain/value_objects/variant_availability_status.dart';
import '../../domain/entities/future_stock_entry.dart';
import '../../domain/repositories/future_stock_repository.dart';
import '../../domain/value_objects/future_stock_source.dart';

@LazySingleton(as: FutureStockRepository)
final class ProductVariantFutureStockRepository
    implements FutureStockRepository {
  const ProductVariantFutureStockRepository(this._variants);

  final ProductVariantRepository _variants;

  @override
  Future<List<FutureStockEntry>> listByProductIds({
    required String organizationId,
    required Iterable<String> productIds,
  }) async {
    final entries = <FutureStockEntry>[];
    for (final productId
        in productIds.map((id) => id.trim()).where((id) => id.isNotEmpty)) {
      final result = await _variants.listByProduct(
        organizationId: organizationId,
        productId: productId,
      );
      if (result case AppSuccess<List<ProductVariant>>(value: final variants)) {
        entries.addAll(variants.expand(_entriesForVariant));
      }
    }
    return entries
      ..sort((left, right) => left.expectedDate.compareTo(right.expectedDate));
  }

  @override
  Future<List<FutureStockEntry>> listByVariantIds({
    required String organizationId,
    required Iterable<String> variantIds,
  }) async {
    final entries = <FutureStockEntry>[];
    for (final variantId
        in variantIds.map((id) => id.trim()).where((id) => id.isNotEmpty)) {
      final result = await _variants.getById(
        organizationId: organizationId,
        id: variantId,
      );
      if (result case AppSuccess<ProductVariant>(value: final variant)) {
        entries.addAll(_entriesForVariant(variant));
      }
    }
    return entries
      ..sort((left, right) => left.expectedDate.compareTo(right.expectedDate));
  }

  Iterable<FutureStockEntry> _entriesForVariant(ProductVariant variant) sync* {
    if (variant.manualAvailabilityStatus !=
            VariantAvailabilityStatus.futureStock ||
        variant.manualFutureAvailableAt == null ||
        (variant.manualAvailableQuantity ?? 0) <= 0) {
      return;
    }

    yield FutureStockEntry(
      variantId: variant.id,
      productId: variant.productId,
      warehouseId: null,
      quantity: variant.manualAvailableQuantity!,
      expectedDate: variant.manualFutureAvailableAt!.toUtc(),
      source: FutureStockSource.manualForecast,
    );
  }
}
