import '../../../../core/errors/errors.dart';

/// Plain-JSON shape of one entry in `calculatePricing`'s
/// `items[].appliedDiscounts` (`functions/src/pricing/pricing-engine.ts`'s
/// `PricingEngineAppliedDiscount`).
final class OrderPricingAppliedDiscountDto {
  const OrderPricingAppliedDiscountDto({
    required this.origin,
    required this.amount,
    required this.description,
    this.campaignId,
  });

  factory OrderPricingAppliedDiscountDto.fromJson(Map<String, dynamic> json) {
    final origin = json['origin'];
    final amount = json['amount'];
    final description = json['description'];
    final campaignId = json['campaignId'];

    if (origin is! String ||
        amount is! num ||
        description is! String ||
        (campaignId != null && campaignId is! String)) {
      throw const ServerException(
        'Unexpected calculatePricing appliedDiscounts response shape.',
        code: 'invalid_order_pricing_applied_discount_response',
      );
    }

    return OrderPricingAppliedDiscountDto(
      origin: origin,
      amount: amount.toDouble(),
      description: description,
      campaignId: campaignId as String?,
    );
  }

  final String origin;
  final double amount;
  final String description;
  final String? campaignId;
}

/// Plain-JSON shape of one entry in `calculatePricing`'s `items[]`
/// (`CalculatePricingResponse['items']`,
/// `functions/src/pricing/pricing-engine.ts`'s `PricingEngineItemOutput`) —
/// only the fields TASK-099's commercial summary actually shows/uses are
/// parsed; `approvalRequest`'s own payload is not needed here since
/// [OrderPricingSummaryDto.approvalRequired] already surfaces the same
/// signal at the summary level.
final class OrderPricingSummaryItemDto {
  const OrderPricingSummaryItemDto({
    required this.productId,
    required this.quantity,
    required this.baseUnitPrice,
    required this.finalUnitPrice,
    required this.lineSubtotal,
    required this.lineTotal,
    required this.validationStatus,
    this.variantId,
    this.appliedDiscounts = const <OrderPricingAppliedDiscountDto>[],
  });

  factory OrderPricingSummaryItemDto.fromJson(Map<String, dynamic> json) {
    final productId = json['productId'];
    final variantId = json['variantId'];
    final quantity = json['quantity'];
    final baseUnitPrice = json['baseUnitPrice'];
    final finalUnitPrice = json['finalUnitPrice'];
    final lineSubtotal = json['lineSubtotal'];
    final lineTotal = json['lineTotal'];
    final validationStatus = json['validationStatus'];
    final rawAppliedDiscounts = json['appliedDiscounts'];

    if (productId is! String ||
        (variantId != null && variantId is! String) ||
        quantity is! num ||
        baseUnitPrice is! num ||
        finalUnitPrice is! num ||
        lineSubtotal is! num ||
        lineTotal is! num ||
        validationStatus is! String ||
        rawAppliedDiscounts is! List) {
      throw const ServerException(
        'Unexpected calculatePricing items response shape.',
        code: 'invalid_order_pricing_item_response',
      );
    }

    return OrderPricingSummaryItemDto(
      productId: productId,
      variantId: variantId as String?,
      quantity: quantity.toInt(),
      baseUnitPrice: baseUnitPrice.toDouble(),
      finalUnitPrice: finalUnitPrice.toDouble(),
      lineSubtotal: lineSubtotal.toDouble(),
      lineTotal: lineTotal.toDouble(),
      validationStatus: validationStatus,
      appliedDiscounts: rawAppliedDiscounts
          .map(
            (discount) => OrderPricingAppliedDiscountDto.fromJson(
              Map<String, dynamic>.from(discount as Map),
            ),
          )
          .toList(growable: false),
    );
  }

  final String productId;
  final String? variantId;
  final int quantity;
  final double baseUnitPrice;
  final double finalUnitPrice;
  final double lineSubtotal;
  final double lineTotal;
  final String validationStatus;
  final List<OrderPricingAppliedDiscountDto> appliedDiscounts;
}

/// Plain-JSON shape of `calculatePricing`'s callable response
/// (`functions/src/pricing/calculate-pricing.ts`'s
/// `CalculatePricingResponse`) — `correlationId`/`idempotencyKey`/
/// `clientTotalDiverged`/`tolerance` are not parsed here: TASK-099 never
/// sends a `clientOrderTotal` to compare against, so those fields carry no
/// information for this use case.
final class OrderPricingSummaryDto {
  const OrderPricingSummaryDto({
    required this.currency,
    required this.subtotal,
    required this.campaignDiscountTotal,
    required this.manualDiscountTotal,
    required this.paymentTermAdjustmentTotal,
    required this.shippingAmount,
    required this.total,
    required this.blocked,
    required this.approvalRequired,
    this.items = const <OrderPricingSummaryItemDto>[],
  });

  factory OrderPricingSummaryDto.fromJson(Map<String, dynamic> json) {
    final currency = json['currency'];
    final subtotal = json['subtotal'];
    final campaignDiscountTotal = json['campaignDiscountTotal'];
    final manualDiscountTotal = json['manualDiscountTotal'];
    final paymentTermAdjustmentTotal = json['paymentTermAdjustmentTotal'];
    final shippingAmount = json['shippingAmount'];
    final total = json['total'];
    final blocked = json['blocked'];
    final approvalRequired = json['approvalRequired'];
    final rawItems = json['items'];

    if (currency is! String ||
        subtotal is! num ||
        campaignDiscountTotal is! num ||
        manualDiscountTotal is! num ||
        paymentTermAdjustmentTotal is! num ||
        shippingAmount is! num ||
        total is! num ||
        blocked is! bool ||
        approvalRequired is! bool ||
        rawItems is! List) {
      throw const ServerException(
        'Unexpected calculatePricing callable response shape.',
        code: 'invalid_order_pricing_summary_response',
      );
    }

    return OrderPricingSummaryDto(
      currency: currency,
      subtotal: subtotal.toDouble(),
      campaignDiscountTotal: campaignDiscountTotal.toDouble(),
      manualDiscountTotal: manualDiscountTotal.toDouble(),
      paymentTermAdjustmentTotal: paymentTermAdjustmentTotal.toDouble(),
      shippingAmount: shippingAmount.toDouble(),
      total: total.toDouble(),
      blocked: blocked,
      approvalRequired: approvalRequired,
      items: rawItems
          .map(
            (item) => OrderPricingSummaryItemDto.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
    );
  }

  final String currency;
  final double subtotal;
  final double campaignDiscountTotal;
  final double manualDiscountTotal;
  final double paymentTermAdjustmentTotal;
  final double shippingAmount;
  final double total;
  final bool blocked;
  final bool approvalRequired;
  final List<OrderPricingSummaryItemDto> items;
}
