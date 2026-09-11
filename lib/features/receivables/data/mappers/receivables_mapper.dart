import '../../domain/entities/billing_status_check.dart';
import '../../domain/entities/receivable.dart';
import '../../domain/value_objects/billing_status.dart';
import '../../domain/value_objects/receivable_status.dart';
import '../dtos/billing_status_check_dto.dart';
import '../dtos/receivable_dto.dart';

extension ReceivableDtoMapper on ReceivableDto {
  Receivable toDomain() => Receivable(
    id: id,
    organizationId: organizationId,
    customerId: customerId,
    invoiceId: invoiceId,
    orderId: orderId,
    installmentNumber: installmentNumber,
    dueDate: dueDate,
    amount: amount,
    paidAmount: paidAmount,
    currency: currency,
    status: ReceivableStatus.fromCode(status),
  );
}

extension BillingStatusCheckDtoMapper on BillingStatusCheckDto {
  BillingStatusCheck toDomain() => BillingStatusCheck(
    status: BillingStatus.fromCode(status),
    message: message,
  );
}
