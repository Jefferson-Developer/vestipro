import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/orders/orders.dart';

void main() {
  group('ConvertQuoteToOrderUseCase', () {
    test(
      'surfaces seller confirmation when quote conversion has differences',
      () async {
        final quote = Quote(
          id: 'quote-1',
          organizationId: 'org-1',
          companyId: 'company-1',
          orderDraftId: 'draft-1',
          customerId: 'customer-1',
          sellerId: 'seller-1',
          priceListId: 'price-list-1',
          paymentTermId: 'term-1',
          currency: 'BRL',
          subtotal: 100,
          discountAmount: 0,
          surchargeAmount: 0,
          shippingAmount: 0,
          total: 100,
          status: QuoteStatus.sent,
          expiresAt: DateTime.utc(2026, 1, 8),
          createdAt: DateTime.utc(2026, 1),
          itemCount: 1,
        );
        final repository = _FakeOrderQuoteRepository(
          conversionResult: AppSuccess<QuoteConversionResult>(
            QuoteConversionResult(
              quote: quote,
              totalChanged: true,
              availabilityChanged: true,
              currentTotal: 112,
              message: 'Revise antes de converter.',
            ),
          ),
        );
        final useCase = ConvertQuoteToOrderUseCase(repository);

        final result = await useCase(
          organizationId: 'org-1',
          quoteId: 'quote-1',
          orderId: 'order-1',
        );

        expect(result, isA<AppSuccess<QuoteConversionResult>>());
        final value = (result as AppSuccess<QuoteConversionResult>).value;
        expect(value.requiresSellerConfirmation, isTrue);
        expect(value.currentTotal, 112);
        expect(repository.lastAcceptChanges, isFalse);
      },
    );
  });
}

final class _FakeOrderQuoteRepository implements OrderQuoteRepository {
  _FakeOrderQuoteRepository({required this.conversionResult});

  final AppResult<QuoteConversionResult> conversionResult;
  bool? lastAcceptChanges;

  @override
  Future<AppResult<QuoteConversionResult>> convertToOrder({
    required String organizationId,
    required String quoteId,
    required String orderId,
    required bool acceptChanges,
  }) async {
    lastAcceptChanges = acceptChanges;
    return conversionResult;
  }

  @override
  Future<AppResult<Quote>> generate({
    required Order order,
    required Duration validity,
  }) {
    throw UnimplementedError();
  }
}
