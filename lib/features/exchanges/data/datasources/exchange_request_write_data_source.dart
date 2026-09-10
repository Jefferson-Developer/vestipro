import '../../domain/entities/exchange_request_item.dart';
import '../../domain/value_objects/exchange_reason_category.dart';
import '../../domain/value_objects/exchange_request_status.dart';
import '../dtos/exchange_request_submission_result_dto.dart';
import '../dtos/exchange_request_decision_result_dto.dart';

abstract interface class ExchangeRequestWriteDataSource {
  Future<ExchangeRequestSubmissionResultDto> create({
    required String organizationId,
    required String companyId,
    required String orderId,
    required String exchangeRequestId,
    required List<ExchangeRequestItemInput> items,
    required ExchangeReasonCategory reasonCategory,
    String? reasonDetails,
  });

  Future<ExchangeRequestDecisionResultDto> resolve({
    required String organizationId,
    required String companyId,
    required String exchangeRequestId,
    required ExchangeRequestDecisionValue decision,
    String? reason,
  });
}
