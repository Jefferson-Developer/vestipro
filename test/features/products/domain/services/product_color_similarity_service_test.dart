import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('ProductColorSimilarityService', () {
    const service = ProductColorSimilarityService();

    ProductColor color({
      required String id,
      required String name,
      required String hex,
      String organizationId = 'org-1',
    }) {
      final now = DateTime.utc(2026, 1, 1);
      return ProductColor(
        id: id,
        organizationId: organizationId,
        code: id,
        name: name,
        hex: HexColor.parse(hex),
        status: ProductColorStatus.available,
        createdAt: now,
        createdBy: 'user-1',
        updatedAt: now,
        updatedBy: 'user-1',
        version: 1,
        syncStatus: ProductSyncStatus.pending,
      );
    }

    test('suggests equivalent colors by normalized name', () {
      final suggestions = service.findSimilar(
        name: 'Azul Marinho',
        hex: HexColor.parse('#102A44'),
        existingColors: <ProductColor>[
          color(id: 'color-1', name: 'Azul-marinho', hex: '#445566'),
        ],
      );

      expect(suggestions, hasLength(1));
      expect(suggestions.single.color.id, 'color-1');
      expect(suggestions.single.reason, 'Nome muito parecido');
    });

    test('suggests equivalent colors by close hex distance', () {
      final suggestions = service.findSimilar(
        name: 'Noite',
        hex: HexColor.parse('#102A44'),
        existingColors: <ProductColor>[
          color(id: 'color-1', name: 'Oceano', hex: '#112B45'),
        ],
      );

      expect(suggestions.single.color.id, 'color-1');
      expect(suggestions.single.reason, 'Hexadecimal visualmente próximo');
    });

    test('does not suggest distant colors with different names', () {
      final suggestions = service.findSimilar(
        name: 'Vermelho',
        hex: HexColor.parse('#FF0000'),
        existingColors: <ProductColor>[
          color(id: 'color-1', name: 'Azul', hex: '#0000FF'),
        ],
      );

      expect(suggestions, isEmpty);
    });
  });
}
