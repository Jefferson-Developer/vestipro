import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/product_recommendations/product_recommendations.dart';

Map<String, dynamic> _validJson({List<dynamic>? items}) {
  return <String, dynamic>{
    'organizationId': 'org-1',
    'companyId': 'company-1',
    'scopeType': 'product',
    'scopeId': 'product-1',
    'items':
        items ??
        <Map<String, dynamic>>[
          {
            'productId': 'product-2',
            'productName': 'Calça Jeans',
            'score': 0.5,
            'reasonCode': 'boughtTogether',
            'reasonLabel':
                'Clientes que compraram Camiseta Básica também compraram Calça Jeans.',
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
  };
}

void main() {
  group('ProductRecommendationDto.fromJson', () {
    test('parses a valid payload with items', () {
      final dto = ProductRecommendationDto.fromJson(_validJson(), id: 'doc-1');

      expect(dto.id, 'doc-1');
      expect(dto.scopeType, 'product');
      expect(dto.scopeId, 'product-1');
      expect(dto.items, hasLength(1));
      expect(dto.items.first.productId, 'product-2');
      expect(dto.items.first.reasonCode, 'boughtTogether');
      expect(dto.fallbackApplied, isFalse);
      expect(dto.insufficientData, isFalse);
      expect(dto.signalsUsed, ['order_submitted_item_co_occurrence']);
    });

    test('parses an insufficientData payload with an empty items list', () {
      final json = _validJson(items: const <Map<String, dynamic>>[])
        ..['insufficientData'] = true
        ..['signalsUsed'] = <String>[];

      final dto = ProductRecommendationDto.fromJson(json, id: 'doc-2');

      expect(dto.insufficientData, isTrue);
      expect(dto.items, isEmpty);
      expect(dto.signalsUsed, isEmpty);
    });

    test('throws ValidationException for a missing required field', () {
      final json = _validJson()..remove('scopeType');
      expect(
        () => ProductRecommendationDto.fromJson(json, id: 'doc-1'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('throws ValidationException for a malformed item entry', () {
      final json = _validJson(
        items: <Map<String, dynamic>>[
          {'productId': 'product-2'},
        ],
      );
      expect(
        () => ProductRecommendationDto.fromJson(json, id: 'doc-1'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('round-trips toJson -> fromJson', () {
      final dto = ProductRecommendationDto.fromJson(_validJson(), id: 'doc-1');
      final roundTripped = ProductRecommendationDto.fromJson(
        dto.toJson(),
        id: dto.id,
      );

      expect(roundTripped.scopeType, dto.scopeType);
      expect(roundTripped.items.first.productId, dto.items.first.productId);
      expect(roundTripped.generatedAt, dto.generatedAt);
    });
  });
}
