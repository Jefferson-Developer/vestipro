import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/order_signature.dart';
import '../../domain/entities/order_signature_submission_result.dart';
import '../../domain/repositories/order_signature_submission_repository.dart';
import '../datasources/order_signature_submission_data_source.dart';
import '../mappers/order_signature_submission_mapper.dart';

/// [OrderSignatureSubmissionRepository] backed by
/// [OrderSignatureSubmissionDataSource] (EPIC-13, TASK-180) — mirrors
/// `OrderSubmissionRepositoryImpl`'s own shape for `Order` itself.
@LazySingleton(as: OrderSignatureSubmissionRepository)
final class OrderSignatureSubmissionRepositoryImpl
    implements OrderSignatureSubmissionRepository {
  const OrderSignatureSubmissionRepositoryImpl({
    required this.dataSource,
    required this.mapper,
  });

  final OrderSignatureSubmissionDataSource dataSource;
  final OrderSignatureSubmissionMapper mapper;

  @override
  Future<AppResult<OrderSignatureSubmissionResult>> submit({
    required OrderSignature signature,
  }) async {
    try {
      final dto = await dataSource.submit(signature: signature);
      return AppSuccess<OrderSignatureSubmissionResult>(mapper.toEntity(dto));
    } on AppException catch (exception) {
      return AppFailure<OrderSignatureSubmissionResult>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<OrderSignatureSubmissionResult>(
        UnexpectedFailure(
          'Unexpected error submitting the order signature.',
          code: 'order_signature_submission_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
