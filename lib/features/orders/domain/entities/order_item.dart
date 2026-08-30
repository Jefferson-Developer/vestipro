import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_item.freezed.dart';

/// One product-color-size variant line inside an `Order` (EPIC-13,
/// TASK-095).
///
/// [unitPrice] is always the price returned by the pricing engine
/// (`ResolvePriceForVariantUseCase`, TASK-088) at the moment the item is
/// added to the order — it is captured here and never recalculated
/// retroactively without an explicit audit trail; a later price change to
/// the same variant/Price List must not silently change an item already on
/// an order. [subtotal] is likewise a captured value (`quantity * unitPrice`
/// adjusted by [discountAmount]/[surchargeAmount]), not a derived getter,
/// for the same auditability reason — whichever later task computes it must
/// still store the result here rather than let every reader recompute it.
///
/// No submission, pricing or approval rule is implemented in this task: this
/// entity only models the shape TASK-096 onward will fill in.
@freezed
abstract class OrderItem with _$OrderItem {
  const OrderItem._();

  const factory OrderItem({
    required String id,
    required String variantId,
    // Denormalized from the variant's product for display without a join.
    required String productId,
    required int quantity,
    required double unitPrice,
    @Default(0) double discountAmount,
    @Default(0) double surchargeAmount,
    required double subtotal,
  }) = _OrderItem;

  /// `quantity * unitPrice`, before [discountAmount]/[surchargeAmount] — a
  /// convenience for UI/validation, never a substitute for the captured
  /// [subtotal] itself.
  double get grossAmount => quantity * unitPrice;
}
