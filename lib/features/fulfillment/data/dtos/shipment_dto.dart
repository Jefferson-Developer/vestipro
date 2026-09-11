import 'package:cloud_firestore/cloud_firestore.dart';

/// `organizations/{organizationId}/shipments/{shipmentId}` document shape
/// (TASK-214) — mirrors the server's own shipment document written by
/// `createShipment`/`registerTrackingEvent` (`fulfillment-shared.ts`) field
/// for field, defaulting safely on a missing/partial field rather than
/// throwing.
final class ShipmentPackageItemDto {
  const ShipmentPackageItemDto({
    required this.orderItemId,
    required this.productId,
    required this.variantId,
    required this.quantity,
  });

  factory ShipmentPackageItemDto.fromJson(Map<String, dynamic> json) {
    return ShipmentPackageItemDto(
      orderItemId: json['orderItemId'] as String? ?? '',
      productId: json['productId'] as String? ?? '',
      variantId: json['variantId'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }

  final String orderItemId;
  final String productId;
  final String variantId;
  final int quantity;
}

final class ShipmentPackageDto {
  const ShipmentPackageDto({
    required this.packageNumber,
    required this.items,
    this.weightKg,
  });

  factory ShipmentPackageDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return ShipmentPackageDto(
      packageNumber: (json['packageNumber'] as num?)?.toInt() ?? 0,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      items: rawItems is List
          ? rawItems
                .whereType<Map<dynamic, dynamic>>()
                .map(
                  (item) => ShipmentPackageItemDto.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
          : const <ShipmentPackageItemDto>[],
    );
  }

  final int packageNumber;
  final double? weightKg;
  final List<ShipmentPackageItemDto> items;
}

final class ShipmentDto {
  const ShipmentDto({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.orderId,
    this.orderNumber,
    required this.customerId,
    required this.sellerId,
    this.carrierName,
    this.carrierTrackingCode,
    required this.status,
    required this.hasOpenIssue,
    required this.packages,
    required this.deliveredQuantities,
    this.estimatedDeliveryDate,
    this.shippedAt,
    this.deliveredAt,
    this.lastEventAt,
    required this.createdAt,
  });

  factory ShipmentDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final rawPackages = json['packages'];
    final rawDelivered = json['deliveredQuantities'];
    return ShipmentDto(
      id: id,
      organizationId: json['organizationId'] as String? ?? '',
      companyId: json['companyId'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      orderNumber: json['orderNumber'] as String?,
      customerId: json['customerId'] as String? ?? '',
      sellerId: json['sellerId'] as String? ?? '',
      carrierName: json['carrierName'] as String?,
      carrierTrackingCode: json['carrierTrackingCode'] as String?,
      status: json['status'] as String? ?? 'pending',
      hasOpenIssue: json['hasOpenIssue'] as bool? ?? false,
      packages: rawPackages is List
          ? rawPackages
                .whereType<Map<dynamic, dynamic>>()
                .map(
                  (pkg) => ShipmentPackageDto.fromJson(
                    Map<String, dynamic>.from(pkg),
                  ),
                )
                .toList(growable: false)
          : const <ShipmentPackageDto>[],
      deliveredQuantities: rawDelivered is Map
          ? rawDelivered.map(
              (key, value) =>
                  MapEntry(key as String, (value as num?)?.toInt() ?? 0),
            )
          : const <String, int>{},
      estimatedDeliveryDate: _asDate(json['estimatedDeliveryDate']),
      shippedAt: _asDate(json['shippedAt']),
      deliveredAt: _asDate(json['deliveredAt']),
      lastEventAt: _asDate(json['lastEventAt']),
      createdAt: _asDate(json['createdAt']) ?? DateTime.now(),
    );
  }

  final String id;
  final String organizationId;
  final String companyId;
  final String orderId;
  final String? orderNumber;
  final String customerId;
  final String sellerId;
  final String? carrierName;
  final String? carrierTrackingCode;
  final String status;
  final bool hasOpenIssue;
  final List<ShipmentPackageDto> packages;
  final Map<String, int> deliveredQuantities;
  final DateTime? estimatedDeliveryDate;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final DateTime? lastEventAt;
  final DateTime createdAt;

  /// Never actually sent to Firestore (`Shipment` is read-only from the
  /// client, `firestore.rules` denies every write) — kept only for symmetry
  /// with [ShipmentDto.fromJson], same convention `PostSaleEventDto` already
  /// follows for its own read-only documents.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'organizationId': organizationId,
    'companyId': companyId,
    'orderId': orderId,
    'orderNumber': orderNumber,
    'customerId': customerId,
    'sellerId': sellerId,
    'carrierName': carrierName,
    'carrierTrackingCode': carrierTrackingCode,
    'status': status,
    'hasOpenIssue': hasOpenIssue,
    'packages': packages
        .map(
          (pkg) => <String, dynamic>{
            'packageNumber': pkg.packageNumber,
            'weightKg': pkg.weightKg,
            'items': pkg.items
                .map(
                  (item) => <String, dynamic>{
                    'orderItemId': item.orderItemId,
                    'productId': item.productId,
                    'variantId': item.variantId,
                    'quantity': item.quantity,
                  },
                )
                .toList(growable: false),
          },
        )
        .toList(growable: false),
    'deliveredQuantities': deliveredQuantities,
    'estimatedDeliveryDate': estimatedDeliveryDate == null
        ? null
        : Timestamp.fromDate(estimatedDeliveryDate!),
    'shippedAt': shippedAt == null ? null : Timestamp.fromDate(shippedAt!),
    'deliveredAt': deliveredAt == null
        ? null
        : Timestamp.fromDate(deliveredAt!),
    'lastEventAt': lastEventAt == null
        ? null
        : Timestamp.fromDate(lastEventAt!),
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

DateTime? _asDate(Object? value) => value is Timestamp ? value.toDate() : null;
