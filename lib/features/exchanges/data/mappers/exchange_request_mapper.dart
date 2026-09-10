import '../../domain/entities/exchange_request.dart';
import '../../domain/entities/exchange_request_decision.dart';
import '../../domain/entities/exchange_request_item.dart';
import '../../domain/value_objects/exchange_reason_category.dart';
import '../../domain/value_objects/exchange_request_status.dart';
import '../dtos/exchange_request_dto.dart';

extension ExchangeRequestItemDtoMapper on ExchangeRequestItemDto {
  ExchangeRequestItem toDomain() => ExchangeRequestItem(
    orderItemId: orderItemId,
    originProductId: originProductId,
    originVariantId: originVariantId,
    originUnitPrice: originUnitPrice,
    destinationVariantId: destinationVariantId,
    destinationProductId: destinationProductId,
    quantity: quantity,
  );
}

extension ExchangeRequestDecisionDtoMapper on ExchangeRequestDecisionDto {
  ExchangeRequestDecision toDomain() => ExchangeRequestDecision(
    decision: decision == 'approved'
        ? ExchangeRequestDecisionValue.approved
        : ExchangeRequestDecisionValue.rejected,
    actorId: actorId,
    actorName: actorName,
    reason: reason,
    decidedAt: decidedAt,
  );
}

extension ExchangeRequestDtoMapper on ExchangeRequestDto {
  ExchangeRequest toDomain() => ExchangeRequest(
    id: id,
    organizationId: organizationId,
    companyId: companyId,
    orderId: orderId,
    orderNumber: orderNumber,
    customerId: customerId,
    sellerId: sellerId,
    currency: currency,
    items: items.map((item) => item.toDomain()).toList(growable: false),
    reasonCategory: ExchangeReasonCategory.fromCode(reasonCategory),
    reasonDetails: reasonDetails,
    status: ExchangeRequestStatus.fromCode(status),
    priceDifferenceAmount: priceDifferenceAmount,
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
