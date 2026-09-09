import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

final class ProductRecommendationItemDto {
  const ProductRecommendationItemDto({
    required this.productId,
    required this.productName,
    required this.score,
    required this.reasonCode,
    required this.reasonLabel,
    this.relatedProductId,
    this.relatedProductName,
  });

  factory ProductRecommendationItemDto.fromJson(Map<String, dynamic> json) {
    final productId = json['productId'];
    final productName = json['productName'];
    final score = json['score'];
    final reasonCode = json['reasonCode'];
    final reasonLabel = json['reasonLabel'];
    final relatedProductId = json['relatedProductId'];
    final relatedProductName = json['relatedProductName'];
    if (productId is! String ||
        productName is! String ||
        score is! num ||
        reasonCode is! String ||
        reasonLabel is! String ||
        (relatedProductId != null && relatedProductId is! String) ||
        (relatedProductName != null && relatedProductName is! String)) {
      throw const ValidationException(
        'Invalid product recommendation item payload.',
        code: 'invalid_product_recommendation_item_payload',
      );
    }
    return ProductRecommendationItemDto(
      productId: productId,
      productName: productName,
      score: score.toDouble(),
      reasonCode: reasonCode,
      reasonLabel: reasonLabel,
      relatedProductId: relatedProductId as String?,
      relatedProductName: relatedProductName as String?,
    );
  }

  final String productId;
  final String productName;
  final double score;
  final String reasonCode;
  final String reasonLabel;
  final String? relatedProductId;
  final String? relatedProductName;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'productId': productId,
      'productName': productName,
      'score': score,
      'reasonCode': reasonCode,
      'reasonLabel': reasonLabel,
      'relatedProductId': relatedProductId,
      'relatedProductName': relatedProductName,
    };
  }
}

final class ProductRecommendationDto {
  const ProductRecommendationDto({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.scopeType,
    required this.scopeId,
    required this.items,
    required this.fallbackApplied,
    required this.insufficientData,
    required this.signalsUsed,
    required this.lookbackDays,
    required this.model,
    required this.modelVersion,
    required this.generatedAt,
    required this.version,
  });

  factory ProductRecommendationDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final organizationId = json['organizationId'];
    final companyId = json['companyId'];
    final scopeType = json['scopeType'];
    final scopeId = json['scopeId'];
    final items = json['items'];
    final fallbackApplied = json['fallbackApplied'];
    final insufficientData = json['insufficientData'];
    final signalsUsed = json['signalsUsed'];
    final lookbackDays = json['lookbackDays'];
    final model = json['model'];
    final modelVersion = json['modelVersion'];
    final generatedAt = json['generatedAt'];
    final version = json['version'];

    if (organizationId is! String ||
        companyId is! String ||
        scopeType is! String ||
        scopeId is! String ||
        items is! List ||
        fallbackApplied is! bool ||
        insufficientData is! bool ||
        signalsUsed is! List ||
        lookbackDays is! int ||
        model is! String ||
        modelVersion is! String ||
        generatedAt is! Timestamp ||
        version is! int) {
      throw const ValidationException(
        'Invalid product recommendation payload.',
        code: 'invalid_product_recommendation_payload',
      );
    }

    return ProductRecommendationDto(
      id: id,
      organizationId: organizationId,
      companyId: companyId,
      scopeType: scopeType,
      scopeId: scopeId,
      items: items
          .map(
            (entry) => ProductRecommendationItemDto.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList(growable: false),
      fallbackApplied: fallbackApplied,
      insufficientData: insufficientData,
      signalsUsed: signalsUsed
          .map((entry) => entry as String)
          .toList(growable: false),
      lookbackDays: lookbackDays,
      model: model,
      modelVersion: modelVersion,
      generatedAt: generatedAt.toDate(),
      version: version,
    );
  }

  final String id;
  final String organizationId;
  final String companyId;
  final String scopeType;
  final String scopeId;
  final List<ProductRecommendationItemDto> items;
  final bool fallbackApplied;
  final bool insufficientData;
  final List<String> signalsUsed;
  final int lookbackDays;
  final String model;
  final String modelVersion;
  final DateTime generatedAt;
  final int version;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'companyId': companyId,
      'scopeType': scopeType,
      'scopeId': scopeId,
      'items': items.map((item) => item.toJson()).toList(),
      'fallbackApplied': fallbackApplied,
      'insufficientData': insufficientData,
      'signalsUsed': signalsUsed,
      'lookbackDays': lookbackDays,
      'model': model,
      'modelVersion': modelVersion,
      'generatedAt': Timestamp.fromDate(generatedAt),
      'version': version,
    };
  }
}
