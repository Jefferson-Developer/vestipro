import 'package:injectable/injectable.dart';

import '../../domain/entities/order_pricing_summary.dart';
import '../dtos/order_pricing_summary_dto.dart';

/// Translates `calculatePricing`'s plain-JSON response DTOs
/// ([OrderPricingSummaryDto]) into the domain's [OrderPricingSummary] —
/// every numeric field is copied as-is, never recomputed, per TASK-099's
/// "nunca um cálculo divergente feito apenas na interface" rule.
@injectable
final class OrderPricingMapper {
  const OrderPricingMapper();

  OrderPricingSummary toEntity(OrderPricingSummaryDto dto) {
    return OrderPricingSummary(
      currency: dto.currency,
      subtotal: dto.subtotal,
      campaignDiscountTotal: dto.campaignDiscountTotal,
      manualDiscountTotal: dto.manualDiscountTotal,
      paymentTermAdjustmentTotal: dto.paymentTermAdjustmentTotal,
      shippingAmount: dto.shippingAmount,
      total: dto.total,
      blocked: dto.blocked,
      approvalRequired: dto.approvalRequired,
      items: dto.items.map(_itemToEntity).toList(growable: false),
    );
  }

  OrderPricingItemSummary _itemToEntity(OrderPricingSummaryItemDto dto) {
    return OrderPricingItemSummary(
      productId: dto.productId,
      variantId: dto.variantId,
      quantity: dto.quantity,
      baseUnitPrice: dto.baseUnitPrice,
      finalUnitPrice: dto.finalUnitPrice,
      lineSubtotal: dto.lineSubtotal,
      lineTotal: dto.lineTotal,
      validationStatus: OrderPricingItemValidationStatus.fromWire(
        dto.validationStatus,
      ),
      appliedDiscounts: dto.appliedDiscounts
          .map(
            (discount) => OrderPricingAppliedDiscount(
              origin: OrderPricingDiscountOrigin.fromWire(discount.origin),
              description: discount.description,
              amount: discount.amount,
              productId: dto.productId,
              variantId: dto.variantId,
              campaignId: discount.campaignId,
            ),
          )
          .toList(growable: false),
    );
  }
}
