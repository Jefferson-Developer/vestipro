/// Where one [OrderPricingAppliedDiscount] came from — mirrors
/// `PricingEngineAppliedDiscount['origin']`
/// (`functions/src/pricing/pricing-engine.ts`) verbatim: a campaign discount
/// is never presented as if it were a manual one, or vice-versa, since the
/// seller/approver needs to know exactly which rule produced it.
enum OrderPricingDiscountOrigin {
  campaign,
  manual;

  static OrderPricingDiscountOrigin fromWire(String value) {
    return switch (value) {
      'campaign' => OrderPricingDiscountOrigin.campaign,
      'manual' => OrderPricingDiscountOrigin.manual,
      _ => throw ArgumentError.value(
        value,
        'value',
        'Unknown pricing discount origin.',
      ),
    };
  }
}

/// One discount applied to one order item by the pricing engine
/// (`calculatePricing`, TASK-088) — [description] is the engine's own
/// human-readable reason (e.g. "Campaign Verão applied.", "Manual discount
/// 10.00%."), never a client-invented label, satisfying TASK-099's "descontos
/// aplicados (com origem/motivo)" requirement.
final class OrderPricingAppliedDiscount {
  const OrderPricingAppliedDiscount({
    required this.origin,
    required this.description,
    required this.amount,
    required this.productId,
    this.variantId,
    this.campaignId,
  });

  final OrderPricingDiscountOrigin origin;
  final String description;
  final double amount;
  final String productId;
  final String? variantId;
  final String? campaignId;
}

/// Whether the manual discount on one item is within the seller's discount
/// policy, needs approval, or is outright blocked — mirrors
/// `DiscountValidationStatus` (`functions/src/pricing/pricing-engine.ts`)
/// verbatim; never re-derived client-side.
enum OrderPricingItemValidationStatus {
  allowed,
  requiresApproval,
  blocked;

  static OrderPricingItemValidationStatus fromWire(String value) {
    return switch (value) {
      'allowed' => OrderPricingItemValidationStatus.allowed,
      'requires_approval' => OrderPricingItemValidationStatus.requiresApproval,
      'blocked' => OrderPricingItemValidationStatus.blocked,
      _ => throw ArgumentError.value(
        value,
        'value',
        'Unknown pricing item validation status.',
      ),
    };
  }
}

/// Per-item breakdown returned by `calculatePricing`, kept only for the
/// commercial summary to explain [OrderPricingSummary.approvalRequired]/
/// [OrderPricingSummary.blocked] and to source
/// [OrderPricingSummary.appliedDiscounts] — never used to recompute a total,
/// [OrderPricingSummary.total] already is that total.
final class OrderPricingItemSummary {
  const OrderPricingItemSummary({
    required this.productId,
    required this.quantity,
    required this.baseUnitPrice,
    required this.finalUnitPrice,
    required this.lineSubtotal,
    required this.lineTotal,
    required this.validationStatus,
    this.variantId,
    this.appliedDiscounts = const <OrderPricingAppliedDiscount>[],
  });

  final String productId;
  final String? variantId;
  final int quantity;
  final double baseUnitPrice;
  final double finalUnitPrice;
  final double lineSubtotal;
  final double lineTotal;
  final OrderPricingItemValidationStatus validationStatus;
  final List<OrderPricingAppliedDiscount> appliedDiscounts;
}

/// Result of `calculatePricing` (TASK-088's server-side pricing engine) for
/// the order draft's current items (TASK-099) — the single source of truth
/// for what the seller is shown as subtotal/desconto/acréscimo/frete/total.
/// No field here is ever recomputed or overridden by the UI: every value is
/// exactly what the Cloud Function returned.
///
/// [taxAmount] is deliberately absent: `calculatePricingEngine`
/// (`functions/src/pricing/pricing-engine.ts`) does not compute taxes yet, so
/// there is nothing authoritative to show — inventing a client-side tax
/// figure would violate the very rule this entity exists to enforce. A tax
/// line can be added here once the pricing engine itself returns one.
final class OrderPricingSummary {
  const OrderPricingSummary({
    required this.currency,
    required this.subtotal,
    required this.campaignDiscountTotal,
    required this.manualDiscountTotal,
    required this.paymentTermAdjustmentTotal,
    required this.shippingAmount,
    required this.total,
    required this.blocked,
    required this.approvalRequired,
    this.items = const <OrderPricingItemSummary>[],
  });

  final String currency;
  final double subtotal;
  final double campaignDiscountTotal;
  final double manualDiscountTotal;

  /// "Acréscimo" — additional cost/adjustment tied to the selected payment
  /// term (e.g. a surcharge for an extended term). Always the engine's own
  /// value; `0` when the payment term carries no adjustment.
  final double paymentTermAdjustmentTotal;
  final double shippingAmount;
  final double total;

  /// `true` when at least one item's manual discount is blocked by the
  /// seller's discount policy — the order cannot be submitted as-is.
  final bool blocked;

  /// `true` when at least one item's manual discount exceeds the policy's
  /// automatic threshold and requires approval (TASK-103) before submission
  /// — must always be surfaced to the seller, never hidden (`tasks.md`).
  final bool approvalRequired;
  final List<OrderPricingItemSummary> items;

  double get discountTotal => campaignDiscountTotal + manualDiscountTotal;

  bool get hasDiscounts => discountTotal > 0;

  /// Every discount actually applied, across every item, flattened for
  /// display — each entry keeps which item/variant/campaign it came from.
  List<OrderPricingAppliedDiscount> get appliedDiscounts =>
      <OrderPricingAppliedDiscount>[
        for (final item in items) ...item.appliedDiscounts,
      ];
}
