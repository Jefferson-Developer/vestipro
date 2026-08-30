import '../../../../core/utils/utils.dart';
import '../entities/order_pricing_item_request.dart';
import '../entities/order_pricing_summary.dart';

/// Contract for invoking the server-side pricing engine
/// (`calculatePricing`, TASK-088) for an order draft's current items
/// (TASK-099). The single implementation ([CloudFunctionsOrderPricingRepository])
/// never talks to Firestore/Storage directly — only the callable Cloud
/// Function, same rule every other Cloud-Function-backed repository in this
/// codebase follows.
abstract interface class OrderPricingRepository {
  Future<AppResult<OrderPricingSummary>> calculate({
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
