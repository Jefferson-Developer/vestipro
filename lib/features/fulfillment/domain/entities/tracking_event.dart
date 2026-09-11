import '../value_objects/tracking_event_type.dart';
import 'shipment_package_item.dart';

/// One immutable milestone of a `Shipment`'s own tracking history (TASK-214,
/// EPIC-32) — append-only: a correction is always a brand new
/// [TrackingEventType.adjustment] event carrying [correctionOfEventId], never
/// an edit/overwrite of an existing document (`tasks.md`: "Tracking event é
/// append-only; correção cria novo evento de ajuste, não sobrescreve
/// histórico").
final class TrackingEvent {
  const TrackingEvent({
    required this.id,
    required this.organizationId,
    required this.shipmentId,
    required this.orderId,
    this.orderNumber,
    required this.customerId,
    required this.sellerId,
    required this.type,
    required this.source,
    this.externalEventId,
    this.carrierId,
    this.description,
    this.deliveredItems,
    this.correctionOfEventId,
    required this.occurredAt,
    required this.createdAt,
    required this.createdBy,
    this.createdByName,
  });

  final String id;
  final String organizationId;
  final String shipmentId;
  final String orderId;
  final String? orderNumber;
  final String customerId;
  final String sellerId;
  final TrackingEventType type;
  final TrackingEventSource source;
  final String? externalEventId;
  final String? carrierId;
  final String? description;
  final List<DeliveredItem>? deliveredItems;
  final String? correctionOfEventId;
  final DateTime occurredAt;
  final DateTime createdAt;
  final String createdBy;
  final String? createdByName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackingEvent &&
          other.id == id &&
          other.organizationId == organizationId &&
          other.shipmentId == shipmentId &&
          other.orderId == orderId &&
          other.type == type &&
          other.source == source &&
          other.externalEventId == externalEventId &&
          other.carrierId == carrierId &&
          other.description == description &&
          other.correctionOfEventId == correctionOfEventId &&
          other.occurredAt == occurredAt &&
          other.createdAt == createdAt &&
          other.createdBy == createdBy);

  @override
  int get hashCode => Object.hash(
    id,
    organizationId,
    shipmentId,
    orderId,
    type,
    source,
    externalEventId,
    carrierId,
    description,
    correctionOfEventId,
    occurredAt,
    createdAt,
    createdBy,
  );
}
