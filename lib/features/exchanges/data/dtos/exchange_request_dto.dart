import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

final class ExchangeRequestItemDto {
  const ExchangeRequestItemDto({
    required this.orderItemId,
    required this.originProductId,
    required this.originVariantId,
    required this.originUnitPrice,
    required this.destinationVariantId,
    required this.destinationProductId,
    required this.quantity,
  });

  factory ExchangeRequestItemDto.fromJson(Map<String, dynamic> json) {
    final orderItemId = json['orderItemId'];
    final originProductId = json['originProductId'];
    final originVariantId = json['originVariantId'];
    final originUnitPrice = json['originUnitPrice'];
    final destinationVariantId = json['destinationVariantId'];
    final destinationProductId = json['destinationProductId'];
    final quantity = json['quantity'];
    if (orderItemId is! String ||
        originProductId is! String ||
        originVariantId is! String ||
        originUnitPrice is! num ||
        destinationVariantId is! String ||
        destinationProductId is! String ||
        quantity is! num) {
      throw const ValidationException(
        'Invalid exchange request item payload.',
        code: 'invalid_exchange_request_item_payload',
      );
    }
    return ExchangeRequestItemDto(
      orderItemId: orderItemId,
      originProductId: originProductId,
      originVariantId: originVariantId,
      originUnitPrice: originUnitPrice.toDouble(),
      destinationVariantId: destinationVariantId,
      destinationProductId: destinationProductId,
      quantity: quantity.toInt(),
    );
  }

  final String orderItemId;
  final String originProductId;
  final String originVariantId;
  final double originUnitPrice;
  final String destinationVariantId;
  final String destinationProductId;
  final int quantity;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'orderItemId': orderItemId,
    'originProductId': originProductId,
    'originVariantId': originVariantId,
    'originUnitPrice': originUnitPrice,
    'destinationVariantId': destinationVariantId,
    'destinationProductId': destinationProductId,
    'quantity': quantity,
  };
}

final class ExchangeRequestDecisionDto {
  const ExchangeRequestDecisionDto({
    required this.decision,
    required this.actorId,
    this.actorName,
    this.reason,
    required this.decidedAt,
  });

  factory ExchangeRequestDecisionDto.fromJson(Map<String, dynamic> json) {
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
        'Invalid exchange request decision payload.',
        code: 'invalid_exchange_request_decision_payload',
      );
    }
    return ExchangeRequestDecisionDto(
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

final class ExchangeRequestDto {
  const ExchangeRequestDto({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.orderId,
    this.orderNumber,
    required this.customerId,
    required this.sellerId,
    required this.currency,
    this.items = const <ExchangeRequestItemDto>[],
    required this.reasonCategory,
    this.reasonDetails,
    required this.status,
    this.priceDifferenceAmount,
    required this.requestedBy,
    this.requestedByName,
    required this.requestedAt,
    this.decisions = const <ExchangeRequestDecisionDto>[],
    this.decidedBy,
    this.decidedAt,
    this.decisionReason,
  });

  factory ExchangeRequestDto.fromJson(
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
    final status = json['status'];
    final priceDifferenceAmount = json['priceDifferenceAmount'];
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
        (priceDifferenceAmount != null && priceDifferenceAmount is! num) ||
        requestedBy is! String ||
        (requestedByName != null && requestedByName is! String) ||
        requestedAt is! Timestamp ||
        (decidedBy != null && decidedBy is! String) ||
        (decidedAt != null && decidedAt is! Timestamp) ||
        (decisionReason != null && decisionReason is! String)) {
      throw const ValidationException(
        'Invalid exchange request payload.',
        code: 'invalid_exchange_request_payload',
      );
    }

    return ExchangeRequestDto(
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
      status: status,
      priceDifferenceAmount: (priceDifferenceAmount as num?)?.toDouble(),
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
  final List<ExchangeRequestItemDto> items;
  final String reasonCategory;
  final String? reasonDetails;
  final String status;
  final double? priceDifferenceAmount;
  final String requestedBy;
  final String? requestedByName;
  final DateTime requestedAt;
  final List<ExchangeRequestDecisionDto> decisions;
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
    'status': status,
    'priceDifferenceAmount': priceDifferenceAmount,
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

List<ExchangeRequestItemDto> _itemDtosFromJson(Object? value) {
  if (value == null) return const <ExchangeRequestItemDto>[];
  if (value is! List<dynamic>) {
    throw const ValidationException(
      'Invalid exchange request items payload.',
      code: 'invalid_exchange_request_payload',
    );
  }
  return value
      .map((item) {
        if (item is! Map<String, dynamic>) {
          throw const ValidationException(
            'Invalid exchange request item payload.',
            code: 'invalid_exchange_request_payload',
          );
        }
        return ExchangeRequestItemDto.fromJson(item);
      })
      .toList(growable: false);
}

List<ExchangeRequestDecisionDto> _decisionDtosFromJson(Object? value) {
  if (value == null) return const <ExchangeRequestDecisionDto>[];
  if (value is! List<dynamic>) {
    throw const ValidationException(
      'Invalid exchange request decisions payload.',
      code: 'invalid_exchange_request_payload',
    );
  }
  return value
      .map((decision) {
        if (decision is! Map<String, dynamic>) {
          throw const ValidationException(
            'Invalid exchange request decision payload.',
            code: 'invalid_exchange_request_payload',
          );
        }
        return ExchangeRequestDecisionDto.fromJson(decision);
      })
      .toList(growable: false);
}
