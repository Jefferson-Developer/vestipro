import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/catalog_share/data/dtos/catalog_share_item_dto.dart';

void main() {
  group('CatalogShareItemDto', () {
    test('fromJson parses a well-formed item', () {
      final dto = CatalogShareItemDto.fromJson(<String, dynamic>{
        'productId': 'product-1',
        'name': 'Camisa Linho',
        'imageUrl': 'https://img/1.png',
      });

      expect(dto.productId, 'product-1');
      expect(dto.name, 'Camisa Linho');
      expect(dto.imageUrl, 'https://img/1.png');
    });

    test('fromJson accepts a null imageUrl', () {
      final dto = CatalogShareItemDto.fromJson(<String, dynamic>{
        'productId': 'product-1',
        'name': 'Camisa Linho',
        'imageUrl': null,
      });

      expect(dto.imageUrl, isNull);
    });

    test('fromJson throws ServerException when productId is missing', () {
      expect(
        () => CatalogShareItemDto.fromJson(<String, dynamic>{'name': 'Camisa'}),
        throwsA(isA<ServerException>()),
      );
    });

    test('toJson roundtrips through fromJson', () {
      const dto = CatalogShareItemDto(
        productId: 'product-1',
        name: 'Camisa Linho',
        imageUrl: 'https://img/1.png',
      );

      final roundTripped = CatalogShareItemDto.fromJson(dto.toJson());

      expect(roundTripped.productId, dto.productId);
      expect(roundTripped.name, dto.name);
      expect(roundTripped.imageUrl, dto.imageUrl);
    });
  });
}
