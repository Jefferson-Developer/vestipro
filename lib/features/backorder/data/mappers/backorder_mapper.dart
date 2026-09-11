import '../../domain/entities/backorder_request.dart';
import '../../domain/value_objects/backorder_origin.dart';
import '../../domain/value_objects/backorder_priority.dart';
import '../../domain/value_objects/backorder_status.dart';
import '../dtos/backorder_request_dto.dart';

extension BackorderRequestDtoMapper on BackorderRequestDto {
  BackorderRequest toDomain() => BackorderRequest(
    id: id,
    organizationId: organizationId,
    companyId: companyId,
    customerId: customerId,
    productId: productId,
    variantId: variantId,
    sku: sku,
    quantity: quantity,
    fulfilledQuantity: fulfilledQuantity,
    quantityAtRequest: quantityAtRequest,
    origin: BackorderOrigin.fromCode(origin),
    priority: BackorderPriority.fromCode(priority),
    sellerId: sellerId,
    relatedOrderId: relatedOrderId,
    relatedOrderItemId: relatedOrderItemId,
    requestedDeliveryDate: requestedDeliveryDate,
    estimatedUnitPrice: estimatedUnitPrice,
    notes: notes,
    status: BackorderStatus.fromCode(status),
    resolutionNote: resolutionNote,
    convertedOrderId: convertedOrderId,
    convertedAt: convertedAt,
    expectedAvailabilityDate: expectedAvailabilityDate,
    requestedBy: requestedBy,
    requestedByName: requestedByName,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
