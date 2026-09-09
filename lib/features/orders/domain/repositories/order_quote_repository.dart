import '../../../../core/utils/utils.dart';
import '../entities/order.dart';
import '../entities/quote.dart';

abstract interface class OrderQuoteRepository {
  Future<AppResult<Quote>> generate({
    required Order order,
    required Duration validity,
  });

  Future<AppResult<QuoteConversionResult>> convertToOrder({
    required String organizationId,
    required String quoteId,
    required String orderId,
    required bool acceptChanges,
  });
}
