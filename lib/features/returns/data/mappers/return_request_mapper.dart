import '../../domain/entities/return_request.dart';
import '../../domain/entities/return_request_decision.dart';
import '../../domain/entities/return_request_item.dart';
import '../../domain/value_objects/return_reason_category.dart';
import '../../domain/value_objects/return_request_status.dart';
import '../dtos/return_request_dto.dart';

extension ReturnRequestItemDtoMapper on ReturnRequestItemDto {
  ReturnRequestItem toDomain() => ReturnRequestItem(
    orderItemId: orderItemId,
    productId: productId,
    variantId: variantId,
    quantity: quantity,
    unitPrice: unitPrice,
    subtotal: subtotal,
    warehouseId: warehouseId,
  );
}

extension ReturnRequestDecisionDtoMapper on ReturnRequestDecisionDto {
  ReturnRequestDecision toDomain() => ReturnRequestDecision(
    decision: decision == 'approved'
        ? ReturnRequestDecisionValue.approved
        : ReturnRequestDecisionValue.rejected,
    actorId: actorId,
    actorName: actorName,
    reason: reason,
    decidedAt: decidedAt,
  );
}

extension ReturnRequestDtoMapper on ReturnRequestDto {
  ReturnRequest toDomain() => ReturnRequest(
    id: id,
    organizationId: organizationId,
    companyId: companyId,
    orderId: orderId,
    orderNumber: orderNumber,
    customerId: customerId,
    sellerId: sellerId,
    currency: currency,
    items: items.map((item) => item.toDomain()).toList(growable: false),
    reasonCategory: ReturnReasonCategory.fromCode(reasonCategory),
    reasonDetails: reasonDetails,
    evidenceUrls: evidenceUrls,
    status: ReturnRequestStatus.fromCode(status),
    refundAmount: refundAmount,
    requestedBy: requestedBy,
    requestedByName: requestedByName,
    requestedAt: requestedAt,
    decisions: decisions
        .map((decision) => decision.toDomain())
        .toList(growable: false),
    decidedBy: decidedBy,
    decidedAt: decidedAt,
    decisionReason: decisionReason,
  );
}
