import '../../../inventory/domain/entities/future_stock_entry.dart';
import '../entities/pre_book_program.dart';

final class PreBookFutureStockAllocationRequest {
  const PreBookFutureStockAllocationRequest({
    required this.variantId,
    required this.quantity,
    required this.deliveryWindowId,
  });

  final String variantId;
  final int quantity;
  final String deliveryWindowId;
}

final class PreBookFutureStockAllocationResult {
  const PreBookFutureStockAllocationResult({
    required this.availability,
    required this.blockedReadyStockVariantIds,
  });

  final Map<String, PreBookVariantAvailability> availability;
  final Set<String> blockedReadyStockVariantIds;
}

final class AllocatePreBookFutureStockUseCase {
  const AllocatePreBookFutureStockUseCase();

  PreBookFutureStockAllocationResult call({
    required PreBookProgram program,
    required List<FutureStockEntry> futureStock,
    required List<PreBookFutureStockAllocationRequest> requests,
    Set<String> readyStockVariantIds = const <String>{},
  }) {
    final byVariantAndWindow = <String, PreBookVariantAvailability>{};
    for (final entry in futureStock) {
      final window = program.deliveryWindowForDate(entry.expectedDate);
      if (window == null) continue;
      byVariantAndWindow['${entry.variantId}:${window.id}'] =
          PreBookVariantAvailability.fromFutureStock(
            entry: entry,
            deliveryWindow: window,
          );
    }

    final allocated = <String, PreBookVariantAvailability>{};
    final blockedReadyStock = <String>{};
    for (final request in requests) {
      final key = '${request.variantId}:${request.deliveryWindowId}';
      final availability = byVariantAndWindow[key];
      if (availability == null) {
        if (readyStockVariantIds.contains(request.variantId)) {
          blockedReadyStock.add(request.variantId);
        }
        allocated[request.variantId] = PreBookVariantAvailability(
          variantId: request.variantId,
          productId: '',
          deliveryWindowId: request.deliveryWindowId,
          status: PreBookAvailabilityStatus.unavailable,
          futureQuantity: 0,
        );
        continue;
      }
      allocated[request.variantId] = PreBookVariantAvailability(
        variantId: availability.variantId,
        productId: availability.productId,
        deliveryWindowId: availability.deliveryWindowId,
        status: availability.canPromise(request.quantity)
            ? PreBookAvailabilityStatus.allocated
            : PreBookAvailabilityStatus.unavailable,
        futureQuantity: availability.futureQuantity,
        allocatedQuantity: request.quantity,
        expectedDate: availability.expectedDate,
      );
    }

    return PreBookFutureStockAllocationResult(
      availability: allocated,
      blockedReadyStockVariantIds: blockedReadyStock,
    );
  }
}
