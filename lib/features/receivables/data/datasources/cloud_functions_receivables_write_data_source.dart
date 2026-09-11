import 'package:injectable/injectable.dart';

import '../../../../core/functions/functions.dart';
import '../dtos/billing_status_check_dto.dart';
import 'receivables_write_data_source.dart';

/// [ReceivablesWriteDataSource] backed by [CloudFunctionsService] (TASK-213)
/// — every mutation/preview goes through the `receivables` callables
/// (`checkBillingStatus`, `registerPaymentAllocation`), never a direct
/// Firestore write, same contract `CloudFunctionsCreditWriteDataSource`
/// (TASK-212) already follows.
@LazySingleton(as: ReceivablesWriteDataSource)
final class CloudFunctionsReceivablesWriteDataSource
    implements ReceivablesWriteDataSource {
  const CloudFunctionsReceivablesWriteDataSource(this._functions);
  final CloudFunctionsService _functions;

  @override
  Future<BillingStatusCheckDto> checkBillingStatus({
    required String organizationId,
    required String customerId,
    String? orderId,
  }) async {
    final json = await _functions.call<Map<String, dynamic>>(
      'checkBillingStatus',
      requireAuth: true,
      data: <String, dynamic>{
        'organizationId': organizationId,
        'customerId': customerId,
        if (orderId != null) 'orderId': orderId,
      },
    );
    return BillingStatusCheckDto.fromJson(json);
  }

  @override
  Future<void> registerPaymentAllocation({
    required String organizationId,
    required String receivableId,
    required double amount,
    required String source,
    required String externalReference,
    String? note,
  }) {
    return _functions.call<Map<String, dynamic>>(
      'registerPaymentAllocation',
      requireAuth: true,
      data: <String, dynamic>{
        'organizationId': organizationId,
        'receivableId': receivableId,
        'amount': amount,
        'source': source,
        'externalReference': externalReference,
        'note': note,
      },
    );
  }
}
