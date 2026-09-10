import 'package:injectable/injectable.dart';

import '../../../../core/functions/functions.dart';
import '../../domain/entities/return_request_item.dart';
import '../../domain/value_objects/return_reason_category.dart';
import '../../domain/value_objects/return_request_status.dart';
import '../dtos/return_request_decision_result_dto.dart';
import '../dtos/return_request_submission_result_dto.dart';
import 'return_request_write_data_source.dart';

/// [ReturnRequestWriteDataSource] backed by [CloudFunctionsService]
/// (TASK-199) — calls `createReturnRequest`/`resolveReturnRequest`, never a
/// client-side write to `organizations/{organizationId}/returnRequests`,
/// same rule every other Cloud-Function-backed data source in this codebase
/// follows (`CloudFunctionsOrderSubmissionDataSource`).
@LazySingleton(as: ReturnRequestWriteDataSource)
final class CloudFunctionsReturnRequestDataSource
    implements ReturnRequestWriteDataSource {
  const CloudFunctionsReturnRequestDataSource(this._cloudFunctionsService);

  final CloudFunctionsService _cloudFunctionsService;

  @override
  Future<ReturnRequestSubmissionResultDto> create({
    required String organizationId,
    required String companyId,
    required String orderId,
    required String returnRequestId,
    required List<ReturnRequestItemInput> items,
    required ReturnReasonCategory reasonCategory,
    String? reasonDetails,
    List<String> evidenceUrls = const <String>[],
  }) async {
    final response = await _cloudFunctionsService.call<Map<String, dynamic>>(
      'createReturnRequest',
      data: <String, dynamic>{
        'organizationId': organizationId,
        'companyId': companyId,
        'orderId': orderId,
        'returnRequestId': returnRequestId,
        'items': items
            .map(
              (item) => <String, dynamic>{
                'orderItemId': item.orderItemId,
                'quantity': item.quantity,
              },
            )
            .toList(growable: false),
        'reasonCategory': reasonCategory.code,
        'reasonDetails': ?reasonDetails,
        if (evidenceUrls.isNotEmpty) 'evidenceUrls': evidenceUrls,
      },
      requireAuth: true,
    );
    return ReturnRequestSubmissionResultDto.fromJson(response);
  }

  @override
  Future<ReturnRequestDecisionResultDto> resolve({
    required String organizationId,
    required String companyId,
    required String returnRequestId,
    required ReturnRequestDecisionValue decision,
    String? reason,
  }) async {
    final response = await _cloudFunctionsService.call<Map<String, dynamic>>(
      'resolveReturnRequest',
      data: <String, dynamic>{
        'organizationId': organizationId,
        'companyId': companyId,
        'returnRequestId': returnRequestId,
        'decision': decision.code,
        'reason': ?reason,
      },
      requireAuth: true,
    );
    return ReturnRequestDecisionResultDto.fromJson(response);
  }
}
