import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/order_pricing_item_request.dart';
import '../../domain/entities/order_pricing_summary.dart';
import '../../domain/repositories/order_pricing_repository.dart';
import '../datasources/order_pricing_data_source.dart';
import '../mappers/order_pricing_mapper.dart';

@LazySingleton(as: OrderPricingRepository)
final class OrderPricingRepositoryImpl implements OrderPricingRepository {
  const OrderPricingRepositoryImpl({
    required this.dataSource,
    required this.mapper,
  });

  final OrderPricingDataSource dataSource;
  final OrderPricingMapper mapper;

  @override
  Future<AppResult<OrderPricingSummary>> calculate({
    required String organizationId,
    required String companyId,
    required String customerSegment,
    required String priceListId,
    required String paymentTermId,
    required String idempotencyKey,
    required double shippingAmount,
    required List<OrderPricingItemRequest> items,
  }) async {
    try {
      final dto = await dataSource.calculate(
        organizationId: organizationId,
        companyId: companyId,
        customerSegment: customerSegment,
        priceListId: priceListId,
        paymentTermId: paymentTermId,
        idempotencyKey: idempotencyKey,
        shippingAmount: shippingAmount,
        items: items,
      );
      return AppSuccess<OrderPricingSummary>(mapper.toEntity(dto));
    } on AppException catch (exception) {
      return AppFailure<OrderPricingSummary>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<OrderPricingSummary>(
        UnexpectedFailure(
          'Unexpected error calculating order pricing.',
          code: 'order_pricing_calculate_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
