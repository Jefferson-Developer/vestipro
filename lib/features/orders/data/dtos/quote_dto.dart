import '../../../../core/errors/errors.dart';
import '../../domain/entities/quote.dart';
import '../../domain/value_objects/quote_status.dart';

final class QuoteDto {
  const QuoteDto({
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

  factory QuoteDto.fromJson(Map<String, dynamic> json) {
    final expiresAt = DateTime.tryParse(json['expiresAt'] as String? ?? '');
    final createdAt = DateTime.tryParse(json['createdAt'] as String? ?? '');
    if (expiresAt == null || createdAt == null) {
      throw const ServerException(
        'Unexpected quote date format.',
        code: 'invalid_quote_response',
      );
    }
    return QuoteDto(
      id: _string(json, 'quoteId'),
      organizationId: _string(json, 'organizationId'),
      companyId: _string(json, 'companyId'),
      orderDraftId: _string(json, 'orderDraftId'),
      customerId: _string(json, 'customerId'),
      sellerId: _string(json, 'sellerId'),
      priceListId: _string(json, 'priceListId'),
      paymentTermId: _string(json, 'paymentTermId'),
      currency: _string(json, 'currency'),
      subtotal: _number(json, 'subtotal'),
      discountAmount: _number(json, 'discountAmount'),
      surchargeAmount: _number(json, 'surchargeAmount'),
      shippingAmount: _number(json, 'shippingAmount'),
      total: _number(json, 'total'),
      status: quoteStatusFromWire(_string(json, 'status')),
      expiresAt: expiresAt,
      createdAt: createdAt,
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
    );
  }

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

  Quote toEntity() {
    return Quote(
      id: id,
      organizationId: organizationId,
      companyId: companyId,
      orderDraftId: orderDraftId,
      customerId: customerId,
      sellerId: sellerId,
      priceListId: priceListId,
      paymentTermId: paymentTermId,
      currency: currency,
      subtotal: subtotal,
      discountAmount: discountAmount,
      surchargeAmount: surchargeAmount,
      shippingAmount: shippingAmount,
      total: total,
      status: status,
      expiresAt: expiresAt,
      createdAt: createdAt,
      itemCount: itemCount,
    );
  }
}

String _string(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is String && value.isNotEmpty) return value;
  throw ServerException(
    'Unexpected quote callable response shape.',
    code: 'invalid_quote_response_$field',
  );
}

double _number(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is num) return value.toDouble();
  throw ServerException(
    'Unexpected quote callable response shape.',
    code: 'invalid_quote_response_$field',
  );
}
