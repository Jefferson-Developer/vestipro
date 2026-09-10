import 'package:injectable/injectable.dart';

import '../../../../core/functions/functions.dart';
import '../../domain/entities/exchange_request_item.dart';
import '../../domain/value_objects/exchange_reason_category.dart';
import '../../domain/value_objects/exchange_request_status.dart';
import '../dtos/exchange_request_decision_result_dto.dart';
import '../dtos/exchange_request_submission_result_dto.dart';
import 'exchange_request_write_data_source.dart';

/// [ExchangeRequestWriteDataSource] backed by [CloudFunctionsService]
/// (TASK-200) — calls `createExchangeRequest`/`resolveExchangeRequest`,
/// never a client-side write to `organizations/{organizationId}/exchangeRequests`,
/// same rule `CloudFunctionsReturnRequestDataSource` (TASK-199) already
/// follows.
@LazySingleton(as: ExchangeRequestWriteDataSource)
final class CloudFunctionsExchangeRequestDataSource
    implements ExchangeRequestWriteDataSource {
  const CloudFunctionsExchangeRequestDataSource(this._cloudFunctionsService);

  final CloudFunctionsService _cloudFunctionsService;

  @override
  Future<ExchangeRequestSubmissionResultDto> create({
    required String organizationId,
    required String companyId,
    required String orderId,
    required String exchangeRequestId,
    required List<ExchangeRequestItemInput> items,
    required ExchangeReasonCategory reasonCategory,
    String? reasonDetails,
  }) async {
    final response = await _cloudFunctionsService.call<Map<String, dynamic>>(
      'createExchangeRequest',
      data: <String, dynamic>{
        'organizationId': organizationId,
        'companyId': companyId,
        'orderId': orderId,
        'exchangeRequestId': exchangeRequestId,
        'items': items
            .map(
              (item) => <String, dynamic>{
                'orderItemId': item.orderItemId,
                'destinationVariantId': item.destinationVariantId,
                'quantity': item.quantity,
              },
            )
            .toList(growable: false),
        'reasonCategory': reasonCategory.code,
        'reasonDetails': ?reasonDetails,
      },
      requireAuth: true,
    );
    return ExchangeRequestSubmissionResultDto.fromJson(response);
  }

  @override
  Future<ExchangeRequestDecisionResultDto> resolve({
    required String organizationId,
    required String companyId,
    required String exchangeRequestId,
    required ExchangeRequestDecisionValue decision,
    String? reason,
  }) async {
    final response = await _cloudFunctionsService.call<Map<String, dynamic>>(
      'resolveExchangeRequest',
      data: <String, dynamic>{
        'organizationId': organizationId,
        'companyId': companyId,
        'exchangeRequestId': exchangeRequestId,
        'decision': decision.code,
        'reason': ?reason,
      },
      requireAuth: true,
    );
    return ExchangeRequestDecisionResultDto.fromJson(response);
  }
}
