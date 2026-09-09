import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/product_recommendations/product_recommendations.dart';

void main() {
  group('ProductRecommendationMapper', () {
    test('maps a full DTO with items to the domain entity', () {
      final dto = ProductRecommendationDto.fromJson(<String, dynamic>{
        'organizationId': 'org-1',
        'companyId': 'company-1',
        'scopeType': 'customer',
        'scopeId': 'customer-1',
        'items': <Map<String, dynamic>>[
          {
            'productId': 'product-2',
            'productName': 'Calça Jeans',
            'score': 0.5,
            'reasonCode': 'purchaseHistorySimilarity',
            'reasonLabel': 'Você já comprou X; clientes semelhantes levaram Y.',
            'relatedProductId': 'product-1',
            'relatedProductName': 'Camiseta Básica',
          },
        ],
        'fallbackApplied': false,
        'insufficientData': false,
        'signalsUsed': <String>['order_submitted_item_co_occurrence'],
        'lookbackDays': 180,
        'model': 'itemCoOccurrenceV1',
        'modelVersion': 'co-occurrence-v1',
        'generatedAt': Timestamp.fromDate(DateTime.utc(2026, 9, 8)),
        'version': 1,
      }, id: 'doc-1');

      final entity = const ProductRecommendationMapper().toEntity(dto);

      expect(entity.id, 'doc-1');
      expect(entity.scopeType, ProductRecommendationScopeType.customer);
      expect(entity.scopeId, 'customer-1');
      expect(entity.items, hasLength(1));
      expect(
        entity.items.first.reasonCode,
        ProductRecommendationReasonCode.purchaseHistorySimilarity,
      );
      expect(entity.hasRecommendations, isTrue);
      expect(entity.fallbackApplied, isFalse);
      expect(entity.insufficientData, isFalse);
    });

    test('maps an insufficientData DTO with no items', () {
      final dto = ProductRecommendationDto.fromJson(<String, dynamic>{
        'organizationId': 'org-1',
        'companyId': 'company-1',
        'scopeType': 'customer',
        'scopeId': 'customer-new',
        'items': const <Map<String, dynamic>>[],
        'fallbackApplied': false,
        'insufficientData': true,
        'signalsUsed': const <String>[],
        'lookbackDays': 180,
        'model': 'itemCoOccurrenceV1',
        'modelVersion': 'co-occurrence-v1',
        'generatedAt': Timestamp.fromDate(DateTime.utc(2026, 9, 8)),
        'version': 1,
      }, id: 'doc-2');

      final entity = const ProductRecommendationMapper().toEntity(dto);

      expect(entity.hasRecommendations, isFalse);
      expect(entity.insufficientData, isTrue);
    });
  });
}
