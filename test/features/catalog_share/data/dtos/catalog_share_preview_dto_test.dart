import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/catalog_share/data/dtos/catalog_share_preview_dto.dart';

void main() {
  group('CatalogSharePreviewDto.fromJson', () {
    test('parses a valid outcome with items and expiresAt', () {
      final json = <String, dynamic>{
        'outcome': 'valid',
        'organizationName': 'Grupo Fashion XPTO',
        'scope': 'product',
        'items': <Map<String, dynamic>>[
          {'productId': 'product-1', 'name': 'Camisa Linho', 'imageUrl': null},
        ],
        'collectionName': null,
        'expiresAt': '2026-02-01T00:00:00.000Z',
      };

      final dto = CatalogSharePreviewDto.fromJson(json);

      expect(dto.outcome, 'valid');
      expect(dto.organizationName, 'Grupo Fashion XPTO');
      expect(dto.items, hasLength(1));
      expect(dto.expiresAt, DateTime.parse('2026-02-01T00:00:00.000Z'));
    });

    test('parses a notFound outcome with empty items and null fields', () {
      final json = <String, dynamic>{
        'outcome': 'notFound',
        'organizationName': null,
        'scope': null,
        'items': <Map<String, dynamic>>[],
        'collectionName': null,
        'expiresAt': null,
      };

      final dto = CatalogSharePreviewDto.fromJson(json);

      expect(dto.outcome, 'notFound');
      expect(dto.items, isEmpty);
      expect(dto.expiresAt, isNull);
    });

    test('throws ServerException when outcome is missing', () {
      final json = <String, dynamic>{'items': <Map<String, dynamic>>[]};

      expect(
        () => CatalogSharePreviewDto.fromJson(json),
        throwsA(isA<ServerException>()),
      );
    });

    test('throws ServerException when items is missing', () {
      final json = <String, dynamic>{'outcome': 'valid'};

      expect(
        () => CatalogSharePreviewDto.fromJson(json),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
