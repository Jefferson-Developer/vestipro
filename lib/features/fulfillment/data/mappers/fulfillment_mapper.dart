import '../../domain/entities/logistics_issue.dart';
import '../../domain/entities/shipment.dart';
import '../../domain/entities/shipment_package.dart';
import '../../domain/entities/shipment_package_item.dart';
import '../../domain/entities/tracking_event.dart';
import '../../domain/value_objects/logistics_issue_type.dart';
import '../../domain/value_objects/shipment_status.dart';
import '../../domain/value_objects/tracking_event_type.dart';
import '../dtos/logistics_issue_dto.dart';
import '../dtos/shipment_dto.dart';
import '../dtos/tracking_event_dto.dart';

extension ShipmentDtoMapper on ShipmentDto {
  Shipment toDomain() => Shipment(
    id: id,
    organizationId: organizationId,
    companyId: companyId,
    orderId: orderId,
    orderNumber: orderNumber,
    customerId: customerId,
    sellerId: sellerId,
    carrierName: carrierName,
    carrierTrackingCode: carrierTrackingCode,
    status: ShipmentStatus.fromCode(status),
    hasOpenIssue: hasOpenIssue,
    packages: packages.map((pkg) => pkg.toDomain()).toList(growable: false),
    deliveredQuantities: deliveredQuantities,
    estimatedDeliveryDate: estimatedDeliveryDate,
    shippedAt: shippedAt,
    deliveredAt: deliveredAt,
    lastEventAt: lastEventAt,
    createdAt: createdAt,
  );
}

extension ShipmentPackageDtoMapper on ShipmentPackageDto {
  ShipmentPackage toDomain() => ShipmentPackage(
    packageNumber: packageNumber,
    weightKg: weightKg,
    items: items.map((item) => item.toDomain()).toList(growable: false),
  );
}

extension ShipmentPackageItemDtoMapper on ShipmentPackageItemDto {
  ShipmentPackageItem toDomain() => ShipmentPackageItem(
    orderItemId: orderItemId,
    productId: productId,
    variantId: variantId,
    quantity: quantity,
  );
}

extension TrackingEventDtoMapper on TrackingEventDto {
  TrackingEvent toDomain() => TrackingEvent(
    id: id,
    organizationId: organizationId,
    shipmentId: shipmentId,
    orderId: orderId,
    orderNumber: orderNumber,
    customerId: customerId,
    sellerId: sellerId,
    type: TrackingEventType.fromCode(type),
    source: TrackingEventSource.fromCode(source),
    externalEventId: externalEventId,
    carrierId: carrierId,
    description: description,
    deliveredItems: deliveredItems
        ?.map(
          (item) => DeliveredItem(
            orderItemId: item.orderItemId,
            quantity: item.quantity,
          ),
        )
        .toList(growable: false),
    correctionOfEventId: correctionOfEventId,
    occurredAt: occurredAt,
    createdAt: createdAt,
    createdBy: createdBy,
    createdByName: createdByName,
  );
}

extension LogisticsIssueDtoMapper on LogisticsIssueDto {
  LogisticsIssue toDomain() => LogisticsIssue(
    id: id,
    organizationId: organizationId,
    shipmentId: shipmentId,
    orderId: orderId,
    orderNumber: orderNumber,
    customerId: customerId,
    sellerId: sellerId,
    type: LogisticsIssueType.fromCode(type),
    description: description,
    responsibleUserId: responsibleUserId,
    nextAction: nextAction,
    status: LogisticsIssueStatus.fromCode(status),
    source: source,
    createdAt: createdAt,
    createdBy: createdBy,
    createdByName: createdByName,
    resolvedAt: resolvedAt,
    resolvedBy: resolvedBy,
    resolutionNote: resolutionNote,
  );
}
