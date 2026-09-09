import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

final class CommissionEntryDto {
  const CommissionEntryDto({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.orderId,
    this.orderNumber,
    required this.sellerId,
    this.sellerName,
    this.ruleId,
    required this.baseAmount,
    required this.commissionAmount,
    required this.currency,
    required this.status,
    required this.periodKey,
    required this.sourceEventId,
    required this.sourceEventType,
    required this.occurredAt,
    required this.calculationTrace,
  });

  factory CommissionEntryDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final organizationId = json['organizationId'];
    final companyId = json['companyId'];
    final orderId = json['orderId'];
    final orderNumber = json['orderNumber'];
    final sellerId = json['sellerId'];
    final sellerName = json['sellerName'];
    final ruleId = json['ruleId'];
    final baseAmount = json['baseAmount'];
    final commissionAmount = json['commissionAmount'];
    final currency = json['currency'];
    final status = json['status'];
    final periodKey = json['periodKey'];
    final sourceEventId = json['sourceEventId'];
    final sourceEventType = json['sourceEventType'];
    final occurredAt = json['occurredAt'];
    final calculationTrace = json['calculationTrace'];

    if (organizationId is! String ||
        companyId is! String ||
        orderId is! String ||
        (orderNumber != null && orderNumber is! String) ||
        sellerId is! String ||
        (sellerName != null && sellerName is! String) ||
        (ruleId != null && ruleId is! String) ||
        baseAmount is! num ||
        commissionAmount is! num ||
        currency is! String ||
        status is! String ||
        periodKey is! String ||
        sourceEventId is! String ||
        sourceEventType is! String ||
        occurredAt is! Timestamp ||
        calculationTrace is! Map) {
      throw const ValidationException(
        'Invalid commission entry payload.',
        code: 'invalid_commission_entry_payload',
      );
    }

    return CommissionEntryDto(
      id: id,
      organizationId: organizationId,
      companyId: companyId,
      orderId: orderId,
      orderNumber: orderNumber as String?,
      sellerId: sellerId,
      sellerName: sellerName as String?,
      ruleId: ruleId as String?,
      baseAmount: baseAmount.toDouble(),
      commissionAmount: commissionAmount.toDouble(),
      currency: currency,
      status: status,
      periodKey: periodKey,
      sourceEventId: sourceEventId,
      sourceEventType: sourceEventType,
      occurredAt: occurredAt.toDate(),
      calculationTrace: Map<String, Object?>.from(calculationTrace),
    );
  }

  final String id;
  final String organizationId;
  final String companyId;
  final String orderId;
  final String? orderNumber;
  final String sellerId;
  final String? sellerName;
  final String? ruleId;
  final double baseAmount;
  final double commissionAmount;
  final String currency;
  final String status;
  final String periodKey;
  final String sourceEventId;
  final String sourceEventType;
  final DateTime occurredAt;
  final Map<String, Object?> calculationTrace;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'organizationId': organizationId,
    'companyId': companyId,
    'orderId': orderId,
    'orderNumber': orderNumber,
    'sellerId': sellerId,
    'sellerName': sellerName,
    'ruleId': ruleId,
    'baseAmount': baseAmount,
    'commissionAmount': commissionAmount,
    'currency': currency,
    'status': status,
    'periodKey': periodKey,
    'sourceEventId': sourceEventId,
    'sourceEventType': sourceEventType,
    'occurredAt': Timestamp.fromDate(occurredAt),
    'calculationTrace': calculationTrace,
  };
}
