import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/orders/orders.dart';

void main() {
  test('parses generateQuote response into a Quote entity', () {
    final dto = QuoteDto.fromJson(<String, dynamic>{
      'quoteId': 'quote-1',
      'organizationId': 'org-1',
      'companyId': 'company-1',
      'orderDraftId': 'order-1',
      'customerId': 'customer-1',
      'sellerId': 'seller-1',
      'priceListId': 'price-list-1',
      'paymentTermId': 'term-1',
      'currency': 'BRL',
      'subtotal': 120,
      'discountAmount': 10,
      'surchargeAmount': 2,
      'shippingAmount': 8,
      'total': 120,
      'status': 'sent',
      'expiresAt': '2026-01-08T00:00:00.000Z',
      'createdAt': '2026-01-01T00:00:00.000Z',
      'itemCount': 2,
    });

    final quote = dto.toEntity();

    expect(quote.id, 'quote-1');
    expect(quote.status, QuoteStatus.sent);
    expect(quote.total, 120);
    expect(quote.itemCount, 2);
  });
}
