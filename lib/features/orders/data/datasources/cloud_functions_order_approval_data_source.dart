import 'package:injectable/injectable.dart';

import '../../../../core/functions/functions.dart';
import '../../domain/entities/order_approval_decision.dart';
import '../dtos/order_approval_decision_result_dto.dart';
import 'order_approval_data_source.dart';

/// [OrderApprovalDataSource] backed by [CloudFunctionsService] (TASK-103) —
/// calls `decideOrderApproval`, mirroring
/// `CloudFunctionsOrderSubmissionDataSource`'s own contract.
@LazySingleton(as: OrderApprovalDataSource)
final class CloudFunctionsOrderApprovalDataSource
    implements OrderApprovalDataSource {
  const CloudFunctionsOrderApprovalDataSource(this._cloudFunctionsService);

  final CloudFunctionsService _cloudFunctionsService;

  @override
  Future<OrderApprovalDecisionResultDto> decide({
    required String organizationId,
    required String companyId,
    required String orderId,
    required OrderApprovalDecisionValue decision,
    String? reason,
  }) async {
    final response = await _cloudFunctionsService.call<Map<String, dynamic>>(
      'decideOrderApproval',
      data: <String, dynamic>{
        'organizationId': organizationId,
        'companyId': companyId,
        'orderId': orderId,
        'decision': _decisionToJson(decision),
        if (reason != null) 'reason': reason,
      },
      requireAuth: true,
    );

    return OrderApprovalDecisionResultDto.fromJson(response);
  }

  String _decisionToJson(OrderApprovalDecisionValue decision) {
    return switch (decision) {
      OrderApprovalDecisionValue.approved => 'approved',
      OrderApprovalDecisionValue.rejected => 'rejected',
    };
  }
}
