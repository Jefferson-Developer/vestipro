import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/exchange_request.dart';
import '../../domain/entities/exchange_request_decision_result.dart';
import '../../domain/entities/exchange_request_item.dart';
import '../../domain/entities/exchange_request_submission_result.dart';
import '../../domain/repositories/exchange_request_repository.dart';
import '../../domain/value_objects/exchange_reason_category.dart';
import '../../domain/value_objects/exchange_request_status.dart';
import '../datasources/exchange_request_read_data_source.dart';
import '../datasources/exchange_request_write_data_source.dart';
import '../mappers/exchange_request_mapper.dart';

@LazySingleton(as: ExchangeRequestRepository)
final class ExchangeRequestRepositoryImpl implements ExchangeRequestRepository {
  const ExchangeRequestRepositoryImpl(
    this._readDataSource,
    this._writeDataSource,
  );

  final ExchangeRequestReadDataSource _readDataSource;
  final ExchangeRequestWriteDataSource _writeDataSource;

  @override
  Future<AppResult<ExchangeRequestSubmissionResult>> createExchangeRequest({
    required String organizationId,
    required String companyId,
    required String orderId,
    required String exchangeRequestId,
    required List<ExchangeRequestItemInput> items,
    required ExchangeReasonCategory reasonCategory,
    String? reasonDetails,
  }) async {
    try {
      final result = await _writeDataSource.create(
        organizationId: organizationId,
        companyId: companyId,
        orderId: orderId,
        exchangeRequestId: exchangeRequestId,
        items: items,
        reasonCategory: reasonCategory,
        reasonDetails: reasonDetails,
      );
      return AppSuccess<ExchangeRequestSubmissionResult>(
        ExchangeRequestSubmissionResult(
          exchangeRequestId: result.exchangeRequestId,
          orderId: result.orderId,
          reasonCategory: ExchangeReasonCategory.fromCode(
            result.reasonCategory,
          ),
          requestedAt: result.requestedAt,
        ),
      );
    } on AppException catch (exception) {
      return AppFailure<ExchangeRequestSubmissionResult>(
        mapAppExceptionToFailure(exception),
      );
    } catch (error) {
      return AppFailure<ExchangeRequestSubmissionResult>(
        UnexpectedFailure(
          'Unexpected error creating the exchange request.',
          code: 'exchange_request_create_unexpected',
          cause: error,
        ),
      );
    }
  }

  @override
  Future<AppResult<ExchangeRequestDecisionResult>> resolveExchangeRequest({
    required String organizationId,
    required String companyId,
    required String exchangeRequestId,
    required ExchangeRequestDecisionValue decision,
    String? reason,
  }) async {
    try {
      final result = await _writeDataSource.resolve(
        organizationId: organizationId,
        companyId: companyId,
        exchangeRequestId: exchangeRequestId,
        decision: decision,
        reason: reason,
      );
      return AppSuccess<ExchangeRequestDecisionResult>(
        ExchangeRequestDecisionResult(
          exchangeRequestId: result.exchangeRequestId,
          orderId: result.orderId,
          status: ExchangeRequestStatus.fromCode(result.status),
          decidedBy: result.decidedBy,
          decidedAt: result.decidedAt,
          reason: result.reason,
          priceDifferenceAmount: result.priceDifferenceAmount,
        ),
      );
    } on AppException catch (exception) {
      return AppFailure<ExchangeRequestDecisionResult>(
        mapAppExceptionToFailure(exception),
      );
    } catch (error) {
      return AppFailure<ExchangeRequestDecisionResult>(
        UnexpectedFailure(
          'Unexpected error deciding the exchange request.',
          code: 'exchange_request_resolve_unexpected',
          cause: error,
        ),
      );
    }
  }

  @override
  Stream<AppResult<List<ExchangeRequest>>> watchByOrder({
    required String organizationId,
    required String orderId,
  }) async* {
    try {
      await for (final items in _readDataSource.watchByOrder(
        organizationId: organizationId,
        orderId: orderId,
      )) {
        yield AppSuccess<List<ExchangeRequest>>(
          items.map((item) => item.toDomain()).toList(growable: false),
        );
      }
    } catch (error) {
      yield AppFailure<List<ExchangeRequest>>(
        UnexpectedFailure(
          'Unexpected error loading the exchange request history.',
          code: 'exchange_request_history_watch_unexpected',
          cause: error,
        ),
      );
    }
  }

  @override
  Stream<AppResult<List<ExchangeRequest>>> watchQueue({
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
        yield AppSuccess<List<ExchangeRequest>>(
          items.map((item) => item.toDomain()).toList(growable: false),
        );
      }
    } catch (error) {
      yield AppFailure<List<ExchangeRequest>>(
        UnexpectedFailure(
          'Unexpected error loading the exchange request queue.',
          code: 'exchange_request_queue_watch_unexpected',
          cause: error,
        ),
      );
    }
  }
}
