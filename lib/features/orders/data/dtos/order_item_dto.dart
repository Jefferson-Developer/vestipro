import '../../../../core/errors/errors.dart';

/// Firestore-embedded shape of an `OrderItem` (TASK-095) — nested inside
/// [OrderDto], never its own top-level document.
final class OrderItemDto {
  const OrderItemDto({
    required this.id,
    required this.variantId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.discountAmount,
    required this.surchargeAmount,
    required this.subtotal,
  });

  factory OrderItemDto.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final variantId = json['variantId'];
    final productId = json['productId'];
    final quantity = json['quantity'];
    final unitPrice = json['unitPrice'];
    final discountAmount = json['discountAmount'];
    final surchargeAmount = json['surchargeAmount'];
    final subtotal = json['subtotal'];

    if (id is! String ||
        variantId is! String ||
        productId is! String ||
        quantity is! int ||
        unitPrice is! num ||
        discountAmount is! num ||
        surchargeAmount is! num ||
        subtotal is! num) {
      throw const ValidationException(
        'Invalid order item payload.',
        code: 'invalid_order_payload',
      );
    }

    return OrderItemDto(
      id: id,
      variantId: variantId,
      productId: productId,
      quantity: quantity,
      unitPrice: unitPrice.toDouble(),
      discountAmount: discountAmount.toDouble(),
      surchargeAmount: surchargeAmount.toDouble(),
      subtotal: subtotal.toDouble(),
    );
  }

  final String id;
  final String variantId;
  final String productId;
  final int quantity;
  final double unitPrice;
  final double discountAmount;
  final double surchargeAmount;
  final double subtotal;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'variantId': variantId,
      'productId': productId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'discountAmount': discountAmount,
      'surchargeAmount': surchargeAmount,
      'subtotal': subtotal,
    };
  }
}
