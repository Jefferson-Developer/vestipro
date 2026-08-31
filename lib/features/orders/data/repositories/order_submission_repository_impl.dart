// `injectable` also exports an `Order` annotation (unrelated to this
// feature's `Order` entity) — hidden here, same precedent `OrderMapper`
// already follows.
import 'package:injectable/injectable.dart' hide Order;

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_submission_result.dart';
import '../../domain/repositories/order_submission_repository.dart';
import '../datasources/order_submission_data_source.dart';
import '../mappers/order_submission_mapper.dart';

@LazySingleton(as: OrderSubmissionRepository)
final class OrderSubmissionRepositoryImpl implements OrderSubmissionRepository {
  const OrderSubmissionRepositoryImpl({
    required this.dataSource,
    required this.mapper,
  });

  final OrderSubmissionDataSource dataSource;
  final OrderSubmissionMapper mapper;

  @override
  Future<AppResult<OrderSubmissionResult>> submit({
    required Order order,
    required String idempotencyKey,
  }) async {
    try {
      final dto = await dataSource.submit(
        order: order,
        idempotencyKey: idempotencyKey,
      );
      return AppSuccess<OrderSubmissionResult>(mapper.toEntity(dto));
    } on AppException catch (exception) {
      return AppFailure<OrderSubmissionResult>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<OrderSubmissionResult>(
        UnexpectedFailure(
          'Unexpected error submitting the order.',
          code: 'order_submission_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
