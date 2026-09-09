import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/quote.dart';
import '../../domain/repositories/order_quote_repository.dart';
import '../datasources/order_quote_data_source.dart';

final class OrderQuoteRepositoryImpl implements OrderQuoteRepository {
  const OrderQuoteRepositoryImpl(this._dataSource);

  final OrderQuoteDataSource _dataSource;

  @override
  Future<AppResult<Quote>> generate({
    required Order order,
    required Duration validity,
  }) async {
    try {
      final dto = await _dataSource.generate(order: order, validity: validity);
      return AppSuccess<Quote>(dto.toEntity());
    } on AppException catch (exception) {
      return AppFailure<Quote>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<Quote>(
        UnexpectedFailure(
          'Unexpected error generating the quote.',
          code: 'quote_generation_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<QuoteConversionResult>> convertToOrder({
    required String organizationId,
    required String quoteId,
    required String orderId,
    required bool acceptChanges,
  }) async {
    try {
      final dto = await _dataSource.convertToOrder(
        organizationId: organizationId,
        quoteId: quoteId,
        orderId: orderId,
        acceptChanges: acceptChanges,
      );
      return AppSuccess<QuoteConversionResult>(dto.toEntity());
    } on AppException catch (exception) {
      return AppFailure<QuoteConversionResult>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<QuoteConversionResult>(
        UnexpectedFailure(
          'Unexpected error converting the quote.',
          code: 'quote_conversion_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
