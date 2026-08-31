import '../../../../core/errors/errors.dart';

/// Plain-JSON shape of `submitOrder`'s callable response
/// (`functions/src/orders/submit-order.ts`'s `SubmitOrderResponse`, TASK-101)
/// — `correlationId`/`items` are not parsed here: nothing on this screen
/// shows a per-item breakdown of the just-submitted order (that is TASK-102's
/// listing/detail screen's own job), only the order-level totals/number/
/// status the "Enviar pedido" flow itself needs.
final class OrderSubmissionResultDto {
  const OrderSubmissionResultDto({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.discountAmount,
    required this.surchargeAmount,
    required this.shippingAmount,
    required this.total,
    required this.submittedAt,
  });

  factory OrderSubmissionResultDto.fromJson(Map<String, dynamic> json) {
    final orderId = json['orderId'];
    final orderNumber = json['orderNumber'];
    final status = json['status'];
    final discountAmount = json['discountAmount'];
    final surchargeAmount = json['surchargeAmount'];
    final shippingAmount = json['shippingAmount'];
    final total = json['total'];
    final submittedAt = json['submittedAt'];

    if (orderId is! String ||
        orderNumber is! String ||
        status is! String ||
        discountAmount is! num ||
        surchargeAmount is! num ||
        shippingAmount is! num ||
        total is! num ||
        submittedAt is! String) {
      throw const ServerException(
        'Unexpected submitOrder callable response shape.',
        code: 'invalid_order_submission_response',
      );
    }

    final parsedSubmittedAt = DateTime.tryParse(submittedAt);
    if (parsedSubmittedAt == null) {
      throw const ServerException(
        'Unexpected submitOrder submittedAt format.',
        code: 'invalid_order_submission_response',
      );
    }

    return OrderSubmissionResultDto(
      orderId: orderId,
      orderNumber: orderNumber,
      status: status,
      discountAmount: discountAmount.toDouble(),
      surchargeAmount: surchargeAmount.toDouble(),
      shippingAmount: shippingAmount.toDouble(),
      total: total.toDouble(),
      submittedAt: parsedSubmittedAt,
    );
  }

  final String orderId;
  final String orderNumber;
  final String status;
  final double discountAmount;
  final double surchargeAmount;
  final double shippingAmount;
  final double total;
  final DateTime submittedAt;
}
