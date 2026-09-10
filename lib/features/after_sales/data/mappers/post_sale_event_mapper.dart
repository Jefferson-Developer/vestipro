import '../../domain/entities/post_sale_event.dart';
import '../../domain/value_objects/post_sale_event_type.dart';
import '../dtos/post_sale_event_dto.dart';

extension PostSaleEventDtoMapper on PostSaleEventDto {
  PostSaleEvent toDomain() => PostSaleEvent(
    id: id,
    organizationId: organizationId,
    companyId: companyId,
    orderId: orderId,
    orderNumber: orderNumber,
    customerId: customerId,
    sellerId: sellerId,
    type: PostSaleEventType.fromCode(type),
    description: description,
    source: PostSaleEventSource.fromCode(source),
    sourceRequestId: sourceRequestId,
    createdBy: createdBy,
    createdByName: createdByName,
    createdAt: createdAt,
    notifiedSeller: notifiedSeller,
  );
}
