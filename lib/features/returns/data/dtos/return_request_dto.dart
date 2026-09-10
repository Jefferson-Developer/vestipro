import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

final class ReturnRequestItemDto {
  const ReturnRequestItemDto({
    required this.orderItemId,
    required this.productId,
    required this.variantId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.warehouseId,
  });

  factory ReturnRequestItemDto.fromJson(Map<String, dynamic> json) {
    final orderItemId = json['orderItemId'];
    final productId = json['productId'];
    final variantId = json['variantId'];
    final quantity = json['quantity'];
    final unitPrice = json['unitPrice'];
    final subtotal = json['subtotal'];
    final warehouseId = json['warehouseId'];
    if (orderItemId is! String ||
        productId is! String ||
        variantId is! String ||
        quantity is! num ||
        unitPrice is! num ||
        subtotal is! num ||
        (warehouseId != null && warehouseId is! String)) {
      throw const ValidationException(
        'Invalid return request item payload.',
        code: 'invalid_return_request_item_payload',
      );
    }
    return ReturnRequestItemDto(
      orderItemId: orderItemId,
      productId: productId,
      variantId: variantId,
      quantity: quantity.toInt(),
      unitPrice: unitPrice.toDouble(),
      subtotal: subtotal.toDouble(),
      warehouseId: warehouseId as String?,
    );
  }

  final String orderItemId;
  final String productId;
  final String variantId;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final String? warehouseId;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'orderItemId': orderItemId,
    'productId': productId,
    'variantId': variantId,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'subtotal': subtotal,
    'warehouseId': warehouseId,
  };
}

final class ReturnRequestDecisionDto {
  const ReturnRequestDecisionDto({
    required this.decision,
    required this.actorId,
    this.actorName,
    this.reason,
    required this.decidedAt,
  });

  factory ReturnRequestDecisionDto.fromJson(Map<String, dynamic> json) {
    final decision = json['decision'];
    final actorId = json['actorId'];
    final actorName = json['actorName'];
    final reason = json['reason'];
    final decidedAt = json['decidedAt'];
    if (decision is! String ||
        actorId is! String ||
        (actorName != null && actorName is! String) ||
        (reason != null && reason is! String) ||
        decidedAt is! Timestamp) {
      throw const ValidationException(
        'Invalid return request decision payload.',
        code: 'invalid_return_request_decision_payload',
      );
    }
    return ReturnRequestDecisionDto(
      decision: decision,
      actorId: actorId,
      actorName: actorName as String?,
      reason: reason as String?,
      decidedAt: decidedAt.toDate(),
    );
  }

  final String decision;
  final String actorId;
  final String? actorName;
  final String? reason;
  final DateTime decidedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'decision': decision,
    'actorId': actorId,
    'actorName': actorName,
    'reason': reason,
    'decidedAt': Timestamp.fromDate(decidedAt),
  };
}

final class ReturnRequestDto {
  const ReturnRequestDto({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.orderId,
    this.orderNumber,
    required this.customerId,
    required this.sellerId,
    required this.currency,
    this.items = const <ReturnRequestItemDto>[],
    required this.reasonCategory,
    this.reasonDetails,
    this.evidenceUrls = const <String>[],
    required this.status,
    required this.refundAmount,
    required this.requestedBy,
    this.requestedByName,
    required this.requestedAt,
    this.decisions = const <ReturnRequestDecisionDto>[],
    this.decidedBy,
    this.decidedAt,
    this.decisionReason,
  });

  factory ReturnRequestDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final organizationId = json['organizationId'];
    final companyId = json['companyId'];
    final orderId = json['orderId'];
    final orderNumber = json['orderNumber'];
    final customerId = json['customerId'];
    final sellerId = json['sellerId'];
    final currency = json['currency'];
    final rawItems = json['items'];
    final reasonCategory = json['reasonCategory'];
    final reasonDetails = json['reasonDetails'];
    final rawEvidenceUrls = json['evidenceUrls'];
    final status = json['status'];
    final refundAmount = json['refundAmount'];
    final requestedBy = json['requestedBy'];
    final requestedByName = json['requestedByName'];
    final requestedAt = json['requestedAt'];
    final rawDecisions = json['decisions'];
    final decidedBy = json['decidedBy'];
    final decidedAt = json['decidedAt'];
    final decisionReason = json['decisionReason'];

    if (organizationId is! String ||
        companyId is! String ||
        orderId is! String ||
        (orderNumber != null && orderNumber is! String) ||
        customerId is! String ||
        sellerId is! String ||
        currency is! String ||
        reasonCategory is! String ||
        (reasonDetails != null && reasonDetails is! String) ||
        status is! String ||
        refundAmount is! num ||
        requestedBy is! String ||
        (requestedByName != null && requestedByName is! String) ||
        requestedAt is! Timestamp ||
        (decidedBy != null && decidedBy is! String) ||
        (decidedAt != null && decidedAt is! Timestamp) ||
        (decisionReason != null && decisionReason is! String)) {
      throw const ValidationException(
        'Invalid return request payload.',
        code: 'invalid_return_request_payload',
      );
    }

    return ReturnRequestDto(
      id: id,
      organizationId: organizationId,
      companyId: companyId,
      orderId: orderId,
      orderNumber: orderNumber as String?,
      customerId: customerId,
      sellerId: sellerId,
      currency: currency,
      items: _itemDtosFromJson(rawItems),
      reasonCategory: reasonCategory,
      reasonDetails: reasonDetails as String?,
      evidenceUrls: _stringListFromJson(rawEvidenceUrls),
      status: status,
      refundAmount: refundAmount.toDouble(),
      requestedBy: requestedBy,
      requestedByName: requestedByName as String?,
      requestedAt: requestedAt.toDate(),
      decisions: _decisionDtosFromJson(rawDecisions),
      decidedBy: decidedBy as String?,
      decidedAt: (decidedAt as Timestamp?)?.toDate(),
      decisionReason: decisionReason as String?,
    );
  }

  final String id;
  final String organizationId;
  final String companyId;
  final String orderId;
  final String? orderNumber;
  final String customerId;
  final String sellerId;
  final String currency;
  final List<ReturnRequestItemDto> items;
  final String reasonCategory;
  final String? reasonDetails;
  final List<String> evidenceUrls;
  final String status;
  final double refundAmount;
  final String requestedBy;
  final String? requestedByName;
  final DateTime requestedAt;
  final List<ReturnRequestDecisionDto> decisions;
  final String? decidedBy;
  final DateTime? decidedAt;
  final String? decisionReason;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'organizationId': organizationId,
    'companyId': companyId,
    'orderId': orderId,
    'orderNumber': orderNumber,
    'customerId': customerId,
    'sellerId': sellerId,
    'currency': currency,
    'items': items.map((item) => item.toJson()).toList(growable: false),
    'reasonCategory': reasonCategory,
    'reasonDetails': reasonDetails,
    'evidenceUrls': evidenceUrls,
    'status': status,
    'refundAmount': refundAmount,
    'requestedBy': requestedBy,
    'requestedByName': requestedByName,
    'requestedAt': Timestamp.fromDate(requestedAt),
    'decisions': decisions
        .map((decision) => decision.toJson())
        .toList(growable: false),
    'decidedBy': decidedBy,
    'decidedAt': decidedAt == null ? null : Timestamp.fromDate(decidedAt!),
    'decisionReason': decisionReason,
  };
}

List<ReturnRequestItemDto> _itemDtosFromJson(Object? value) {
  if (value == null) return const <ReturnRequestItemDto>[];
  if (value is! List<dynamic>) {
    throw const ValidationException(
      'Invalid return request items payload.',
      code: 'invalid_return_request_payload',
    );
  }
  return value
      .map((item) {
        if (item is! Map<String, dynamic>) {
          throw const ValidationException(
            'Invalid return request item payload.',
            code: 'invalid_return_request_payload',
          );
        }
        return ReturnRequestItemDto.fromJson(item);
      })
      .toList(growable: false);
}

List<ReturnRequestDecisionDto> _decisionDtosFromJson(Object? value) {
  if (value == null) return const <ReturnRequestDecisionDto>[];
  if (value is! List<dynamic>) {
    throw const ValidationException(
      'Invalid return request decisions payload.',
      code: 'invalid_return_request_payload',
    );
  }
  return value
      .map((decision) {
        if (decision is! Map<String, dynamic>) {
          throw const ValidationException(
            'Invalid return request decision payload.',
            code: 'invalid_return_request_payload',
          );
        }
        return ReturnRequestDecisionDto.fromJson(decision);
      })
      .toList(growable: false);
}

List<String> _stringListFromJson(Object? value) {
  if (value == null) return const <String>[];
  if (value is! List<dynamic> || value.any((item) => item is! String)) {
    throw const ValidationException(
      'Invalid return request string list payload.',
      code: 'invalid_return_request_payload',
    );
  }
  return List<String>.unmodifiable(value.cast<String>());
}
