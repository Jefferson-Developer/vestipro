import '../dtos/billing_status_check_dto.dart';

/// Every receivables mutation/preview (TASK-213) goes through this Cloud
/// Functions surface — never a direct Firestore write, mirroring
/// `CreditWriteDataSource` (TASK-212).
abstract interface class ReceivablesWriteDataSource {
  Future<BillingStatusCheckDto> checkBillingStatus({
    required String organizationId,
    required String customerId,
    String? orderId,
  });

  Future<void> registerPaymentAllocation({
    required String organizationId,
    required String receivableId,
    required double amount,
    required String source,
    required String externalReference,
    String? note,
  });
}
