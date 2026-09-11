import 'package:cloud_firestore/cloud_firestore.dart';

/// `organizations/{organizationId}/trackingEvents/{trackingEventId}`
/// document shape (TASK-214) — mirrors `applyTrackingEvent`'s own write
/// (`register-tracking-event.ts`) field for field.
final class DeliveredItemDto {
  const DeliveredItemDto({required this.orderItemId, required this.quantity});

  factory DeliveredItemDto.fromJson(Map<String, dynamic> json) {
    return DeliveredItemDto(
      orderItemId: json['orderItemId'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }

  final String orderItemId;
  final int quantity;
}

final class TrackingEventDto {
  const TrackingEventDto({
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

  factory TrackingEventDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final rawDelivered = json['deliveredItems'];
    return TrackingEventDto(
      id: id,
      organizationId: json['organizationId'] as String? ?? '',
      shipmentId: json['shipmentId'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      orderNumber: json['orderNumber'] as String?,
      customerId: json['customerId'] as String? ?? '',
      sellerId: json['sellerId'] as String? ?? '',
      type: json['type'] as String? ?? 'adjustment',
      source: json['source'] as String? ?? 'manual',
      externalEventId: json['externalEventId'] as String?,
      carrierId: json['carrierId'] as String?,
      description: json['description'] as String?,
      deliveredItems: rawDelivered is List
          ? rawDelivered
                .whereType<Map<dynamic, dynamic>>()
                .map(
                  (item) => DeliveredItemDto.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
          : null,
      correctionOfEventId: json['correctionOfEventId'] as String?,
      occurredAt: _asDate(json['occurredAt']) ?? DateTime.now(),
      createdAt: _asDate(json['createdAt']) ?? DateTime.now(),
      createdBy: json['createdBy'] as String? ?? '',
      createdByName: json['createdByName'] as String?,
    );
  }

  final String id;
  final String organizationId;
  final String shipmentId;
  final String orderId;
  final String? orderNumber;
  final String customerId;
  final String sellerId;
  final String type;
  final String source;
  final String? externalEventId;
  final String? carrierId;
  final String? description;
  final List<DeliveredItemDto>? deliveredItems;
  final String? correctionOfEventId;
  final DateTime occurredAt;
  final DateTime createdAt;
  final String createdBy;
  final String? createdByName;

  /// Never actually sent to Firestore (`TrackingEvent` is read-only from the
  /// client) — kept only for symmetry with [TrackingEventDto.fromJson].
  Map<String, dynamic> toJson() => <String, dynamic>{
    'organizationId': organizationId,
    'shipmentId': shipmentId,
    'orderId': orderId,
    'orderNumber': orderNumber,
    'customerId': customerId,
    'sellerId': sellerId,
    'type': type,
    'source': source,
    'externalEventId': externalEventId,
    'carrierId': carrierId,
    'description': description,
    'deliveredItems': deliveredItems
        ?.map(
          (item) => <String, dynamic>{
            'orderItemId': item.orderItemId,
            'quantity': item.quantity,
          },
        )
        .toList(growable: false),
    'correctionOfEventId': correctionOfEventId,
    'occurredAt': Timestamp.fromDate(occurredAt),
    'createdAt': Timestamp.fromDate(createdAt),
    'createdBy': createdBy,
    'createdByName': createdByName,
  };
}

DateTime? _asDate(Object? value) => value is Timestamp ? value.toDate() : null;
