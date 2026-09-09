import '../../domain/entities/commission_entry.dart';
import '../dtos/commission_entry_dto.dart';

extension CommissionEntryDtoMapper on CommissionEntryDto {
  CommissionEntry toDomain() => CommissionEntry(
    id: id,
    organizationId: organizationId,
    companyId: companyId,
    orderId: orderId,
    orderNumber: orderNumber,
    sellerId: sellerId,
    sellerName: sellerName,
    ruleId: ruleId,
    baseAmount: baseAmount,
    commissionAmount: commissionAmount,
    currency: currency,
    status: CommissionEntryStatus.fromCode(status),
    periodKey: periodKey,
    sourceEventId: sourceEventId,
    sourceEventType: sourceEventType,
    occurredAt: occurredAt,
    calculationTrace: calculationTrace,
  );
}
