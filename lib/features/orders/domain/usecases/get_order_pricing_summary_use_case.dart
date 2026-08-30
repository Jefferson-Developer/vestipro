import 'package:injectable/injectable.dart' hide Order;

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../customers/domain/usecases/get_customer_by_id_use_case.dart';
import '../entities/order.dart';
import '../entities/order_pricing_item_request.dart';
import '../entities/order_pricing_summary.dart';
import '../repositories/order_pricing_repository.dart';

/// Resolves the commercial summary (subtotal, descontos, acréscimo, frete,
/// total) of an order draft's current items straight from the server-side
/// pricing engine (`calculatePricing`, TASK-088) — TASK-099's "nunca um
/// cálculo divergente feito apenas na interface" rule. This is the only
/// authority `OrderPricingSummaryCubit` calls for the numbers shown on the
/// draft screen's commercial summary card; the provisional
/// `Order.itemsSubtotal` shown next to the items list stays a local, items-
/// only convenience (TASK-097/TASK-098's own docs already say so), never a
/// substitute for this use case's result.
@injectable
final class GetOrderPricingSummaryUseCase {
  const GetOrderPricingSummaryUseCase(this._repository, this._getCustomerById);

  final OrderPricingRepository _repository;
  final GetCustomerByIdUseCase _getCustomerById;

  Future<AppResult<OrderPricingSummary>> call({required Order order}) async {
    if (order.items.isEmpty) {
      return const AppFailure<OrderPricingSummary>(
        ValidationFailure(
          'Order has no items to price.',
          code: 'order_pricing_summary_no_items',
        ),
      );
    }

    // The pricing engine matches campaigns against a customer segment
    // (`PricingEngineCampaign.customerSegment`) it never receives from the
    // client's own guess — this is the same `Customer.segment` already
    // resolved for Price List selection (`ResolveOrderDraftDefaultsUseCase`),
    // fetched again here instead of trusting a stale copy carried since the
    // draft started.
    final customerResult = await _getCustomerById(
      organizationId: order.organizationId,
      id: order.customerId,
    );
    if (customerResult case AppFailure<Customer>(failure: final failure)) {
      return AppFailure<OrderPricingSummary>(failure);
    }
    final customer = (customerResult as AppSuccess<Customer>).value;
    final customerSegment = customer.segment?.trim() ?? '';

    final items = order.items
        .map(
          (item) => OrderPricingItemRequest(
            productId: item.productId,
            variantId: item.variantId,
            quantity: item.quantity,
            collectionId: order.collectionId,
          ),
        )
        .toList(growable: false);

    return _repository.calculate(
      organizationId: order.organizationId,
      companyId: order.companyId,
      customerSegment: customerSegment,
      priceListId: order.priceListId,
      paymentTermId: order.paymentTermId,
      idempotencyKey: _buildIdempotencyKey(order, customerSegment),
      shippingAmount: order.shippingAmount,
      items: items,
    );
  }

  /// A key that only ever repeats for the exact same pricing request
  /// (`calculatePricing` treats a repeated key with a different payload as a
  /// hard conflict, `already-exists` — TASK-088's idempotency contract). This
  /// is deliberately content-derived, not `order.id` alone: this summary is
  /// recalculated on every debounced item/quantity edit
  /// (`OrderPricingSummaryCubit`), so a stable per-order key would collide
  /// with itself the moment the seller changes anything. Editing a value
  /// back to what it was before (e.g. undo) simply reuses the Cloud
  /// Function's own cached response for that content, which is the intended
  /// idempotent behavior, not a bug.
  String _buildIdempotencyKey(Order order, String customerSegment) {
    final fingerprint = Object.hashAll(<Object?>[
      order.priceListId,
      order.paymentTermId,
      order.shippingAmount,
      customerSegment,
      for (final item in order.items) ...<Object?>[
        item.productId,
        item.variantId,
        item.quantity,
      ],
    ]);
    return 'order-pricing-${order.id}-${fingerprint.toRadixString(16)}';
  }
}
