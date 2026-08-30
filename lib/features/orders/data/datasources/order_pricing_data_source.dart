import '../../domain/entities/order_pricing_item_request.dart';
import '../dtos/order_pricing_summary_dto.dart';

/// Source of the raw `calculatePricing` callable response
/// ([OrderPricingSummaryDto]) — the only implementation
/// ([CloudFunctionsOrderPricingDataSource]) never talks to Firestore/Storage,
/// only the Cloud Function itself (TASK-088).
abstract interface class OrderPricingDataSource {
  Future<OrderPricingSummaryDto> calculate({
    required String organizationId,
    required String companyId,
    required String customerSegment,
    required String priceListId,
    required String paymentTermId,
    required String idempotencyKey,
    required double shippingAmount,
    required List<OrderPricingItemRequest> items,
  });
}
