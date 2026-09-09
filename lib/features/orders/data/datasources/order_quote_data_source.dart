import '../../domain/entities/order.dart';
import '../dtos/quote_conversion_result_dto.dart';
import '../dtos/quote_dto.dart';

abstract interface class OrderQuoteDataSource {
  Future<QuoteDto> generate({required Order order, required Duration validity});

  Future<QuoteConversionResultDto> convertToOrder({
    required String organizationId,
    required String quoteId,
    required String orderId,
    required bool acceptChanges,
  });
}
