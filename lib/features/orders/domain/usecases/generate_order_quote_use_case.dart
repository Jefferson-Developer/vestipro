import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/order.dart';
import '../entities/quote.dart';
import '../repositories/order_quote_repository.dart';

final class GenerateOrderQuoteUseCase {
  const GenerateOrderQuoteUseCase(this._repository, this._analyticsService);

  final OrderQuoteRepository _repository;
  final AnalyticsService _analyticsService;

  Future<AppResult<Quote>> call({
    required Order order,
    Duration validity = const Duration(days: 7),
  }) async {
    if (order.items.isEmpty) {
      return const AppFailure<Quote>(
        ValidationFailure(
          'Adicione ao menos um item para gerar o orcamento.',
          code: 'quote_no_items',
        ),
      );
    }
    final result = await _repository.generate(order: order, validity: validity);
    if (result case AppSuccess<Quote>(value: final quote)) {
      await _analyticsService.logEvent(
        'quote_generated',
        parameters: <String, Object?>{
          'organization_id': quote.organizationId,
          'company_id': quote.companyId,
          'quote_id': quote.id,
          'order_draft_id': quote.orderDraftId,
          'total': quote.total,
          'item_count': quote.itemCount,
        },
      );
    }
    return result;
  }
}
