import 'package:cloud_firestore/cloud_firestore.dart';

/// `organizations/{organizationId}/backorders/{backorderId}` document shape
/// (TASK-215) — mirrors the server's own document written by
/// `createBackorderRequest`/`decideBackorderApproval`/
/// `cancelBackorderRequest`/`convertBackorderToOrder`/
/// `notifyBackordersOnStockAvailable` (`backorder-shared.ts`) field for
/// field, defaulting safely on a missing/partial field rather than throwing.
final class BackorderRequestDto {
  const BackorderRequestDto({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.customerId,
    required this.productId,
    required this.variantId,
    this.sku,
    required this.quantity,
    required this.fulfilledQuantity,
    required this.quantityAtRequest,
    required this.origin,
    required this.priority,
    required this.sellerId,
    this.relatedOrderId,
    this.relatedOrderItemId,
    this.requestedDeliveryDate,
    this.estimatedUnitPrice,
    this.notes,
    required this.status,
    this.resolutionNote,
    this.convertedOrderId,
    this.convertedAt,
    this.expectedAvailabilityDate,
    required this.requestedBy,
    this.requestedByName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BackorderRequestDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    return BackorderRequestDto(
      id: id,
      organizationId: json['organizationId'] as String? ?? '',
      companyId: json['companyId'] as String? ?? '',
      customerId: json['customerId'] as String? ?? '',
      productId: json['productId'] as String? ?? '',
      variantId: json['variantId'] as String? ?? '',
      sku: json['sku'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      fulfilledQuantity: (json['fulfilledQuantity'] as num?)?.toInt() ?? 0,
      quantityAtRequest: (json['quantityAtRequest'] as num?)?.toInt() ?? 0,
      origin: json['origin'] as String? ?? 'catalog',
      priority: json['priority'] as String? ?? 'normal',
      sellerId: json['sellerId'] as String? ?? '',
      relatedOrderId: json['relatedOrderId'] as String?,
      relatedOrderItemId: json['relatedOrderItemId'] as String?,
      requestedDeliveryDate: _asDate(json['requestedDeliveryDate']),
      estimatedUnitPrice: (json['estimatedUnitPrice'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'requested',
      resolutionNote: json['resolutionNote'] as String?,
      convertedOrderId: json['convertedOrderId'] as String?,
      convertedAt: _asDate(json['convertedAt']),
      expectedAvailabilityDate: _asDate(json['expectedAvailabilityDate']),
      requestedBy: json['requestedBy'] as String? ?? '',
      requestedByName: json['requestedByName'] as String?,
      createdAt: _asDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _asDate(json['updatedAt']) ?? DateTime.now(),
    );
  }

  final String id;
  final String organizationId;
  final String companyId;
  final String customerId;
  final String productId;
  final String variantId;
  final String? sku;
  final int quantity;
  final int fulfilledQuantity;
  final int quantityAtRequest;
  final String origin;
  final String priority;
  final String sellerId;
  final String? relatedOrderId;
  final String? relatedOrderItemId;
  final DateTime? requestedDeliveryDate;
  final double? estimatedUnitPrice;
  final String? notes;
  final String status;
  final String? resolutionNote;
  final String? convertedOrderId;
  final DateTime? convertedAt;
  final DateTime? expectedAvailabilityDate;
  final String requestedBy;
  final String? requestedByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Never actually sent to Firestore (`BackorderRequest` is read-only from
  /// the client, `firestore.rules` denies every write) — kept only for
  /// symmetry with [BackorderRequestDto.fromJson], same convention
  /// `ShipmentDto` already follows for its own read-only documents.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'organizationId': organizationId,
    'companyId': companyId,
    'customerId': customerId,
    'productId': productId,
    'variantId': variantId,
    'sku': sku,
    'quantity': quantity,
    'fulfilledQuantity': fulfilledQuantity,
    'quantityAtRequest': quantityAtRequest,
    'origin': origin,
    'priority': priority,
    'sellerId': sellerId,
    'relatedOrderId': relatedOrderId,
    'relatedOrderItemId': relatedOrderItemId,
    'requestedDeliveryDate': requestedDeliveryDate == null
        ? null
        : Timestamp.fromDate(requestedDeliveryDate!),
    'estimatedUnitPrice': estimatedUnitPrice,
    'notes': notes,
    'status': status,
    'resolutionNote': resolutionNote,
    'convertedOrderId': convertedOrderId,
    'convertedAt': convertedAt == null
        ? null
        : Timestamp.fromDate(convertedAt!),
    'expectedAvailabilityDate': expectedAvailabilityDate == null
        ? null
        : Timestamp.fromDate(expectedAvailabilityDate!),
    'requestedBy': requestedBy,
    'requestedByName': requestedByName,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };
}

DateTime? _asDate(Object? value) => value is Timestamp ? value.toDate() : null;
