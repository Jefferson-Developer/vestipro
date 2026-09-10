import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/return_request.dart';
import '../../domain/entities/return_request_decision_result.dart';
import '../../domain/entities/return_request_item.dart';
import '../../domain/entities/return_request_submission_result.dart';
import '../../domain/repositories/return_request_repository.dart';
import '../../domain/value_objects/return_reason_category.dart';
import '../../domain/value_objects/return_request_status.dart';
import '../datasources/return_request_read_data_source.dart';
import '../datasources/return_request_write_data_source.dart';
import '../mappers/return_request_mapper.dart';

@LazySingleton(as: ReturnRequestRepository)
final class ReturnRequestRepositoryImpl implements ReturnRequestRepository {
  const ReturnRequestRepositoryImpl(
    this._readDataSource,
    this._writeDataSource,
  );

  final ReturnRequestReadDataSource _readDataSource;
  final ReturnRequestWriteDataSource _writeDataSource;

  @override
  Future<AppResult<ReturnRequestSubmissionResult>> createReturnRequest({
    required String organizationId,
    required String companyId,
    required String orderId,
    required String returnRequestId,
    required List<ReturnRequestItemInput> items,
    required ReturnReasonCategory reasonCategory,
    String? reasonDetails,
    List<String> evidenceUrls = const <String>[],
  }) async {
    try {
      final result = await _writeDataSource.create(
        organizationId: organizationId,
        companyId: companyId,
        orderId: orderId,
        returnRequestId: returnRequestId,
        items: items,
        reasonCategory: reasonCategory,
        reasonDetails: reasonDetails,
        evidenceUrls: evidenceUrls,
      );
      return AppSuccess<ReturnRequestSubmissionResult>(
        ReturnRequestSubmissionResult(
          returnRequestId: result.returnRequestId,
          orderId: result.orderId,
          reasonCategory: ReturnReasonCategory.fromCode(result.reasonCategory),
          refundAmount: result.refundAmount,
          requestedAt: result.requestedAt,
        ),
      );
    } on AppException catch (exception) {
      return AppFailure<ReturnRequestSubmissionResult>(
        mapAppExceptionToFailure(exception),
      );
    } catch (error) {
      return AppFailure<ReturnRequestSubmissionResult>(
        UnexpectedFailure(
          'Unexpected error creating the return request.',
          code: 'return_request_create_unexpected',
          cause: error,
        ),
      );
    }
  }

  @override
  Future<AppResult<ReturnRequestDecisionResult>> resolveReturnRequest({
    required String organizationId,
    required String companyId,
    required String returnRequestId,
    required ReturnRequestDecisionValue decision,
    String? reason,
  }) async {
    try {
      final result = await _writeDataSource.resolve(
        organizationId: organizationId,
        companyId: companyId,
        returnRequestId: returnRequestId,
        decision: decision,
        reason: reason,
      );
      return AppSuccess<ReturnRequestDecisionResult>(
        ReturnRequestDecisionResult(
          returnRequestId: result.returnRequestId,
          orderId: result.orderId,
          status: ReturnRequestStatus.fromCode(result.status),
          decidedBy: result.decidedBy,
          decidedAt: result.decidedAt,
          reason: result.reason,
          resultingOrderStatusLabel: result.resultingOrderStatus,
        ),
      );
    } on AppException catch (exception) {
      return AppFailure<ReturnRequestDecisionResult>(
        mapAppExceptionToFailure(exception),
      );
    } catch (error) {
      return AppFailure<ReturnRequestDecisionResult>(
        UnexpectedFailure(
          'Unexpected error deciding the return request.',
          code: 'return_request_resolve_unexpected',
          cause: error,
        ),
      );
    }
  }

  @override
  Stream<AppResult<List<ReturnRequest>>> watchByOrder({
    required String organizationId,
    required String orderId,
  }) async* {
    try {
      await for (final items in _readDataSource.watchByOrder(
        organizationId: organizationId,
        orderId: orderId,
      )) {
        yield AppSuccess<List<ReturnRequest>>(
          items.map((item) => item.toDomain()).toList(growable: false),
        );
      }
    } catch (error) {
      yield AppFailure<List<ReturnRequest>>(
        UnexpectedFailure(
          'Unexpected error loading the return request history.',
          code: 'return_request_history_watch_unexpected',
          cause: error,
        ),
      );
    }
  }

  @override
  Stream<AppResult<List<ReturnRequest>>> watchQueue({
    required String organizationId,
    required String companyId,
    required bool allCompany,
    Set<String> sellerIds = const <String>{},
  }) async* {
    try {
      await for (final items in _readDataSource.watchQueue(
        organizationId: organizationId,
        companyId: companyId,
        allCompany: allCompany,
        sellerIds: sellerIds,
      )) {
        yield AppSuccess<List<ReturnRequest>>(
          items.map((item) => item.toDomain()).toList(growable: false),
        );
      }
    } catch (error) {
      yield AppFailure<List<ReturnRequest>>(
        UnexpectedFailure(
          'Unexpected error loading the return request queue.',
          code: 'return_request_queue_watch_unexpected',
          cause: error,
        ),
      );
    }
  }
}
