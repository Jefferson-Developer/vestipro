import 'package:injectable/injectable.dart';

import '../../domain/entities/product_recommendation.dart';
import '../../domain/entities/product_recommendation_item.dart';
import '../../domain/value_objects/product_recommendation_reason_code.dart';
import '../../domain/value_objects/product_recommendation_scope_type.dart';
import '../dtos/product_recommendation_dto.dart';

@lazySingleton
final class ProductRecommendationMapper {
  const ProductRecommendationMapper();

  ProductRecommendation toEntity(ProductRecommendationDto dto) {
    return ProductRecommendation(
      id: dto.id,
      organizationId: dto.organizationId,
      companyId: dto.companyId,
      scopeType: parseProductRecommendationScopeType(dto.scopeType),
      scopeId: dto.scopeId,
      items: dto.items.map(_toItemEntity).toList(growable: false),
      fallbackApplied: dto.fallbackApplied,
      insufficientData: dto.insufficientData,
      signalsUsed: dto.signalsUsed,
      lookbackDays: dto.lookbackDays,
      model: dto.model,
      modelVersion: dto.modelVersion,
      generatedAt: dto.generatedAt,
      version: dto.version,
    );
  }

  ProductRecommendationItem _toItemEntity(ProductRecommendationItemDto dto) {
    return ProductRecommendationItem(
      productId: dto.productId,
      productName: dto.productName,
      score: dto.score,
      reasonCode: parseProductRecommendationReasonCode(dto.reasonCode),
      reasonLabel: dto.reasonLabel,
      relatedProductId: dto.relatedProductId,
      relatedProductName: dto.relatedProductName,
    );
  }
}
