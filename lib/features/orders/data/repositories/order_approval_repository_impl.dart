import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/order_approval_decision.dart';
import '../../domain/entities/order_approval_decision_result.dart';
import '../../domain/repositories/order_approval_repository.dart';
import '../datasources/order_approval_data_source.dart';
import '../mappers/order_approval_decision_mapper.dart';

@LazySingleton(as: OrderApprovalRepository)
final class OrderApprovalRepositoryImpl implements OrderApprovalRepository {
  const OrderApprovalRepositoryImpl({
    required this.dataSource,
    required this.mapper,
  });

  final OrderApprovalDataSource dataSource;
  final OrderApprovalDecisionMapper mapper;

  @override
  Future<AppResult<OrderApprovalDecisionResult>> decide({
    required String organizationId,
    required String companyId,
    required String orderId,
    required OrderApprovalDecisionValue decision,
    String? reason,
  }) async {
    try {
      final dto = await dataSource.decide(
        organizationId: organizationId,
        companyId: companyId,
        orderId: orderId,
        decision: decision,
        reason: reason,
      );
      return AppSuccess<OrderApprovalDecisionResult>(mapper.toEntity(dto));
    } on AppException catch (exception) {
      return AppFailure<OrderApprovalDecisionResult>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<OrderApprovalDecisionResult>(
        UnexpectedFailure(
          'Unexpected error deciding the order approval.',
          code: 'order_approval_decision_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
