import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

final class StockAlertDto {
  const StockAlertDto({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.productId,
    required this.variantId,
    required this.warehouseId,
    required this.level,
    required this.transitionType,
    required this.sellableQuantity,
    required this.thresholdQuantity,
    required this.triggeredAt,
    required this.ruleId,
    required this.notificationEventId,
    this.previousLevel,
    this.currentLevel,
  });

  factory StockAlertDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final organizationId = json['organizationId'];
    final companyId = json['companyId'];
    final productId = json['productId'];
    final variantId = json['variantId'];
    final warehouseId = json['warehouseId'];
    final level = json['level'];
    final previousLevel = json['previousLevel'];
    final currentLevel = json['currentLevel'];
    final transitionType = json['transitionType'];
    final sellableQuantity = json['sellableQuantity'];
    final thresholdQuantity = json['thresholdQuantity'];
    final triggeredAt = json['triggeredAt'];
    final ruleId = json['ruleId'];
    final notificationEventId = json['notificationEventId'];

    if (organizationId is! String ||
        companyId is! String ||
        productId is! String ||
        variantId is! String ||
        warehouseId is! String ||
        level is! String ||
        (previousLevel != null && previousLevel is! String) ||
        (currentLevel != null && currentLevel is! String) ||
        transitionType is! String ||
        sellableQuantity is! int ||
        thresholdQuantity is! int ||
        triggeredAt is! Timestamp ||
        ruleId is! String ||
        notificationEventId is! String) {
      throw const ValidationException(
        'Invalid stock alert payload.',
        code: 'invalid_stock_alert_payload',
      );
    }

    return StockAlertDto(
      id: id,
      organizationId: organizationId,
      companyId: companyId,
      productId: productId,
      variantId: variantId,
      warehouseId: warehouseId,
      level: level,
      previousLevel: previousLevel as String?,
      currentLevel: currentLevel as String?,
      transitionType: transitionType,
      sellableQuantity: sellableQuantity,
      thresholdQuantity: thresholdQuantity,
      triggeredAt: triggeredAt.toDate(),
      ruleId: ruleId,
      notificationEventId: notificationEventId,
    );
  }

  final String id;
  final String organizationId;
  final String companyId;
  final String productId;
  final String variantId;
  final String warehouseId;
  final String level;
  final String? previousLevel;
  final String? currentLevel;
  final String transitionType;
  final int sellableQuantity;
  final int thresholdQuantity;
  final DateTime triggeredAt;
  final String ruleId;
  final String notificationEventId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'companyId': companyId,
      'productId': productId,
      'variantId': variantId,
      'warehouseId': warehouseId,
      'level': level,
      'previousLevel': previousLevel,
      'currentLevel': currentLevel,
      'transitionType': transitionType,
      'sellableQuantity': sellableQuantity,
      'thresholdQuantity': thresholdQuantity,
      'triggeredAt': Timestamp.fromDate(triggeredAt),
      'ruleId': ruleId,
      'notificationEventId': notificationEventId,
    };
  }
}
