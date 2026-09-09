import '../value_objects/quote_status.dart';

final class Quote {
  const Quote({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.orderDraftId,
    required this.customerId,
    required this.sellerId,
    required this.priceListId,
    required this.paymentTermId,
    required this.currency,
    required this.subtotal,
    required this.discountAmount,
    required this.surchargeAmount,
    required this.shippingAmount,
    required this.total,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
    required this.itemCount,
  });

  final String id;
  final String organizationId;
  final String companyId;
  final String orderDraftId;
  final String customerId;
  final String sellerId;
  final String priceListId;
  final String paymentTermId;
  final String currency;
  final double subtotal;
  final double discountAmount;
  final double surchargeAmount;
  final double shippingAmount;
  final double total;
  final QuoteStatus status;
  final DateTime expiresAt;
  final DateTime createdAt;
  final int itemCount;

  bool isExpiredAt(DateTime now) => !expiresAt.isAfter(now);
}

final class QuoteConversionResult {
  const QuoteConversionResult({
    required this.quote,
    this.orderId,
    this.orderNumber,
    this.totalChanged = false,
    this.availabilityChanged = false,
    this.currentTotal,
    this.message,
  });

  final Quote quote;
  final String? orderId;
  final String? orderNumber;
  final bool totalChanged;
  final bool availabilityChanged;
  final double? currentTotal;
  final String? message;

  bool get requiresSellerConfirmation => totalChanged || availabilityChanged;
}
