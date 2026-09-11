import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

final class BuyerCollaborationItemDto {
  const BuyerCollaborationItemDto({
    required this.itemId,
    required this.productId,
    required this.productName,
    required this.variantId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory BuyerCollaborationItemDto.fromJson(Map<String, dynamic> json) {
    final itemId = json['itemId'];
    final productId = json['productId'];
    final productName = json['productName'];
    final variantId = json['variantId'];
    final quantity = json['quantity'];
    final unitPrice = json['unitPrice'];
    final subtotal = json['subtotal'];
    if (itemId is! String ||
        productId is! String ||
        productName is! String ||
        variantId is! String ||
        quantity is! num ||
        unitPrice is! num ||
        subtotal is! num) {
      throw const ValidationException(
        'Invalid buyer collaboration item payload.',
        code: 'invalid_buyer_collaboration_item_payload',
      );
    }
    return BuyerCollaborationItemDto(
      itemId: itemId,
      productId: productId,
      productName: productName,
      variantId: variantId,
      quantity: quantity.toInt(),
      unitPrice: unitPrice.toDouble(),
      subtotal: subtotal.toDouble(),
    );
  }

  final String itemId;
  final String productId;
  final String productName;
  final String variantId;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'itemId': itemId,
    'productId': productId,
    'productName': productName,
    'variantId': variantId,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'subtotal': subtotal,
  };
}

final class BuyerCollaborationSessionDto {
  const BuyerCollaborationSessionDto({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.sellerId,
    required this.customerId,
    required this.sourceType,
    required this.sourceId,
    required this.priceListId,
    required this.status,
    this.items = const <BuyerCollaborationItemDto>[],
    required this.showPrices,
    required this.currentTotal,
    this.convertedOrderId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.lastActivityAt,
    required this.expiresAt,
  });

  factory BuyerCollaborationSessionDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final organizationId = json['organizationId'];
    final companyId = json['companyId'];
    final sellerId = json['sellerId'];
    final customerId = json['customerId'];
    final sourceType = json['sourceType'];
    final sourceId = json['sourceId'];
    final priceListId = json['priceListId'];
    final status = json['status'];
    final rawItems = json['items'];
    final showPrices = json['showPrices'];
    final currentTotal = json['currentTotal'];
    final convertedOrderId = json['convertedOrderId'];
    final createdBy = json['createdBy'];
    final createdAt = json['createdAt'];
    final updatedAt = json['updatedAt'];
    final lastActivityAt = json['lastActivityAt'];
    final expiresAt = json['expiresAt'];

    if (organizationId is! String ||
        companyId is! String ||
        sellerId is! String ||
        customerId is! String ||
        sourceType is! String ||
        sourceId is! String ||
        priceListId is! String ||
        status is! String ||
        showPrices is! bool ||
        currentTotal is! num ||
        (convertedOrderId != null && convertedOrderId is! String) ||
        createdBy is! String ||
        createdAt is! Timestamp ||
        updatedAt is! Timestamp ||
        lastActivityAt is! Timestamp ||
        expiresAt is! Timestamp) {
      throw const ValidationException(
        'Invalid buyer collaboration session payload.',
        code: 'invalid_buyer_collaboration_session_payload',
      );
    }

    return BuyerCollaborationSessionDto(
      id: id,
      organizationId: organizationId,
      companyId: companyId,
      sellerId: sellerId,
      customerId: customerId,
      sourceType: sourceType,
      sourceId: sourceId,
      priceListId: priceListId,
      status: status,
      items: _itemDtosFromJson(rawItems),
      showPrices: showPrices,
      currentTotal: currentTotal.toDouble(),
      convertedOrderId: convertedOrderId as String?,
      createdBy: createdBy,
      createdAt: createdAt.toDate(),
      updatedAt: updatedAt.toDate(),
      lastActivityAt: lastActivityAt.toDate(),
      expiresAt: expiresAt.toDate(),
    );
  }

  final String id;
  final String organizationId;
  final String companyId;
  final String sellerId;
  final String customerId;
  final String sourceType;
  final String sourceId;
  final String priceListId;
  final String status;
  final List<BuyerCollaborationItemDto> items;
  final bool showPrices;
  final double currentTotal;
  final String? convertedOrderId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastActivityAt;
  final DateTime expiresAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'organizationId': organizationId,
    'companyId': companyId,
    'sellerId': sellerId,
    'customerId': customerId,
    'sourceType': sourceType,
    'sourceId': sourceId,
    'priceListId': priceListId,
    'status': status,
    'items': items.map((item) => item.toJson()).toList(growable: false),
    'showPrices': showPrices,
    'currentTotal': currentTotal,
    'convertedOrderId': convertedOrderId,
    'createdBy': createdBy,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'lastActivityAt': Timestamp.fromDate(lastActivityAt),
    'expiresAt': Timestamp.fromDate(expiresAt),
  };
}

List<BuyerCollaborationItemDto> _itemDtosFromJson(Object? value) {
  if (value == null) return const <BuyerCollaborationItemDto>[];
  if (value is! List<dynamic>) {
    throw const ValidationException(
      'Invalid buyer collaboration items payload.',
      code: 'invalid_buyer_collaboration_session_payload',
    );
  }
  return value
      .map((item) {
        if (item is! Map<String, dynamic>) {
          throw const ValidationException(
            'Invalid buyer collaboration item payload.',
            code: 'invalid_buyer_collaboration_session_payload',
          );
        }
        return BuyerCollaborationItemDto.fromJson(item);
      })
      .toList(growable: false);
}
