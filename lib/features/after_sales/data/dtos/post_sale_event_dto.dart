import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

/// Firestore document shape for
/// `organizations/{organizationId}/postSaleEvents/{id}` (TASK-201, EPIC-30).
final class PostSaleEventDto {
  const PostSaleEventDto({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.orderId,
    this.orderNumber,
    required this.customerId,
    required this.sellerId,
    required this.type,
    this.description,
    required this.source,
    this.sourceRequestId,
    required this.createdBy,
    this.createdByName,
    required this.createdAt,
    this.notifiedSeller = false,
  });

  factory PostSaleEventDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final organizationId = json['organizationId'];
    final companyId = json['companyId'];
    final orderId = json['orderId'];
    final orderNumber = json['orderNumber'];
    final customerId = json['customerId'];
    final sellerId = json['sellerId'];
    final type = json['type'];
    final description = json['description'];
    final source = json['source'];
    final sourceRequestId = json['sourceRequestId'];
    final createdBy = json['createdBy'];
    final createdByName = json['createdByName'];
    final createdAt = json['createdAt'];
    final notifiedSeller = json['notifiedSeller'];

    if (organizationId is! String ||
        companyId is! String ||
        orderId is! String ||
        (orderNumber != null && orderNumber is! String) ||
        customerId is! String ||
        sellerId is! String ||
        type is! String ||
        (description != null && description is! String) ||
        source is! String ||
        (sourceRequestId != null && sourceRequestId is! String) ||
        createdBy is! String ||
        (createdByName != null && createdByName is! String) ||
        createdAt is! Timestamp ||
        (notifiedSeller != null && notifiedSeller is! bool)) {
      throw const ValidationException(
        'Invalid post-sale event payload.',
        code: 'invalid_post_sale_event_payload',
      );
    }

    return PostSaleEventDto(
      id: id,
      organizationId: organizationId,
      companyId: companyId,
      orderId: orderId,
      orderNumber: orderNumber as String?,
      customerId: customerId,
      sellerId: sellerId,
      type: type,
      description: description as String?,
      source: source,
      sourceRequestId: sourceRequestId as String?,
      createdBy: createdBy,
      createdByName: createdByName as String?,
      createdAt: createdAt.toDate(),
      notifiedSeller: (notifiedSeller as bool?) ?? false,
    );
  }

  final String id;
  final String organizationId;
  final String companyId;
  final String orderId;
  final String? orderNumber;
  final String customerId;
  final String sellerId;

  /// Raw `PostSaleEventType.code` — kept as a string here so the data layer
  /// never has to depend on the domain enum's exact ordering.
  final String type;
  final String? description;

  /// Raw `PostSaleEventSource.code`.
  final String source;
  final String? sourceRequestId;
  final String createdBy;
  final String? createdByName;
  final DateTime createdAt;
  final bool notifiedSeller;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'organizationId': organizationId,
    'companyId': companyId,
    'orderId': orderId,
    'orderNumber': orderNumber,
    'customerId': customerId,
    'sellerId': sellerId,
    'type': type,
    'description': description,
    'source': source,
    'sourceRequestId': sourceRequestId,
    'createdBy': createdBy,
    'createdByName': createdByName,
    'createdAt': Timestamp.fromDate(createdAt),
    'notifiedSeller': notifiedSeller,
  };
}
