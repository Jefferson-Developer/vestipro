// `injectable` also exports an `Order` annotation (unrelated to this
// feature's `Order` entity) — hidden here to avoid an ambiguous import, same
// precedent `OrderMapper`/`OrderLocalMapper` already follow.
import 'package:injectable/injectable.dart' hide Order;

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/order_list_filters.dart';
import '../../domain/entities/order_list_page_result.dart';
import '../../domain/repositories/order_list_repository.dart';
import '../datasources/order_list_data_source.dart';
import '../mappers/order_mapper.dart';

@LazySingleton(as: OrderListRepository)
final class OrderListRepositoryImpl implements OrderListRepository {
  const OrderListRepositoryImpl({
    required this.dataSource,
    required this.mapper,
  });

  final OrderListDataSource dataSource;
  final OrderMapper mapper;

  @override
  Future<AppResult<OrderListPageResult>> listPageByCompany({
    required String organizationId,
    required String companyId,
    int limit = 20,
    DateTime? before,
    OrderListFilters filters = OrderListFilters.empty,
  }) async {
    try {
      final page = await dataSource.listPageByCompany(
        organizationId: organizationId,
        companyId: companyId,
        limit: limit,
        before: before,
        from: filters.from,
        to: filters.to,
        status: filters.status == null
            ? null
            : mapper.statusToDto(filters.status!),
        customerId: filters.customerId,
        orderNumber: filters.orderNumber,
        sellerIds: filters.sellerIds,
      );
      final orders = page.items.map(mapper.toEntity).toList(growable: false);
      return AppSuccess<OrderListPageResult>(
        OrderListPageResult(
          orders: orders,
          hasMore: page.hasMore,
          nextCursor: page.hasMore && orders.isNotEmpty
              ? orders.last.createdAt
              : null,
        ),
      );
    } on AppException catch (exception) {
      return AppFailure<OrderListPageResult>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<OrderListPageResult>(
        UnexpectedFailure(
          'Unexpected error listing orders.',
          code: 'order_list_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
