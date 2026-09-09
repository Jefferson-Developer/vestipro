import '../../../../core/utils/utils.dart';
import '../entities/quote.dart';
import '../repositories/order_quote_repository.dart';

final class ConvertQuoteToOrderUseCase {
  const ConvertQuoteToOrderUseCase(this._repository);

  final OrderQuoteRepository _repository;

  Future<AppResult<QuoteConversionResult>> call({
    required String organizationId,
    required String quoteId,
    required String orderId,
    bool acceptChanges = false,
  }) {
    return _repository.convertToOrder(
      organizationId: organizationId,
      quoteId: quoteId,
      orderId: orderId,
      acceptChanges: acceptChanges,
    );
  }
}
