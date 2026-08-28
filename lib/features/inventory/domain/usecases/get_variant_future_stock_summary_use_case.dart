import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../../products/domain/entities/variant_availability.dart';
import '../../../products/domain/repositories/variant_availability_repository.dart';
import '../entities/future_stock_entry.dart';
import '../entities/variant_future_stock_summary.dart';
import '../repositories/future_stock_repository.dart';

@injectable
final class GetVariantFutureStockSummaryUseCase {
  const GetVariantFutureStockSummaryUseCase(
    this._availabilityRepository,
    this._futureStockRepository,
  );

  final VariantAvailabilityRepository _availabilityRepository;
  final FutureStockRepository _futureStockRepository;

  Future<List<VariantFutureStockSummary>> call({
    required String organizationId,
    required Iterable<String> variantIds,
  }) async {
    final cleanedVariantIds = variantIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (cleanedVariantIds.isEmpty) {
      return const <VariantFutureStockSummary>[];
    }

    final availabilityResult = await _availabilityRepository.listByVariantIds(
      organizationId: organizationId,
      variantIds: cleanedVariantIds,
    );
    final availabilityByVariantId = switch (availabilityResult) {
      AppSuccess<List<VariantAvailability>>(value: final items) =>
        <String, VariantAvailability>{
          for (final item in items) item.variantId: item,
        },
      AppFailure<List<VariantAvailability>>() =>
        const <String, VariantAvailability>{},
    };

    final futureEntries = await _futureStockRepository.listByVariantIds(
      organizationId: organizationId,
      variantIds: cleanedVariantIds,
    );
    final futureByVariantId = <String, List<FutureStockEntry>>{};
    for (final entry in futureEntries) {
      futureByVariantId
          .putIfAbsent(entry.variantId, () => <FutureStockEntry>[])
          .add(entry);
    }
    for (final entries in futureByVariantId.values) {
      entries.sort(
        (left, right) => left.expectedDate.compareTo(right.expectedDate),
      );
    }

    return cleanedVariantIds
        .map((variantId) {
          final availability = availabilityByVariantId[variantId];
          return VariantFutureStockSummary(
            variantId: variantId,
            productId: availability?.productId ?? 'unknown-product',
            immediateQuantity: availability?.availableQuantity ?? 0,
            futureEntries: List<FutureStockEntry>.unmodifiable(
              futureByVariantId[variantId] ?? const <FutureStockEntry>[],
            ),
          );
        })
        .toList(growable: false);
  }
}
