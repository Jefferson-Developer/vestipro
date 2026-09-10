import '../../domain/entities/return_request_item.dart';
import '../../domain/value_objects/return_reason_category.dart';
import '../../domain/value_objects/return_request_status.dart';
import '../dtos/return_request_submission_result_dto.dart';
import '../dtos/return_request_decision_result_dto.dart';

abstract interface class ReturnRequestWriteDataSource {
  Future<ReturnRequestSubmissionResultDto> create({
    required String organizationId,
    required String companyId,
    required String orderId,
    required String returnRequestId,
    required List<ReturnRequestItemInput> items,
    required ReturnReasonCategory reasonCategory,
    String? reasonDetails,
    List<String> evidenceUrls,
  });

  Future<ReturnRequestDecisionResultDto> resolve({
    required String organizationId,
    required String companyId,
    required String returnRequestId,
    required ReturnRequestDecisionValue decision,
    String? reason,
  });
}
