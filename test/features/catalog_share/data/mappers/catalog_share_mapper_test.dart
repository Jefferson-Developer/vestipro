import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/catalog_share/data/dtos/catalog_share_dto.dart';
import 'package:vestipro/features/catalog_share/data/dtos/catalog_share_item_dto.dart';
import 'package:vestipro/features/catalog_share/data/dtos/catalog_share_preview_dto.dart';
import 'package:vestipro/features/catalog_share/data/mappers/catalog_share_mapper.dart';
import 'package:vestipro/features/catalog_share/domain/value_objects/catalog_share_outcome.dart';
import 'package:vestipro/features/catalog_share/domain/value_objects/catalog_share_scope.dart';

void main() {
  group('CatalogShareMapper', () {
    const mapper = CatalogShareMapper();

    test('toEntity maps an active share, deriving isRevoked from status', () {
      final dto = CatalogShareDto(
        id: 'share-1',
        organizationId: 'org-1',
        scope: 'selection',
        items: const [
          CatalogShareItemDto(
            productId: 'product-1',
            name: 'Camisa',
            imageUrl: 'https://img/1.png',
          ),
        ],
        collectionId: null,
        collectionName: null,
        status: 'active',
        openCount: 2,
        firstOpenedAt: DateTime.utc(2026, 1, 2),
        lastOpenedAt: DateTime.utc(2026, 1, 3),
        expiresAt: DateTime.utc(2026, 2, 1),
        createdBy: 'rep-1',
        createdByName: 'Rep Um',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );

      final entity = mapper.toEntity(dto);

      expect(entity.scope, CatalogShareScope.selection);
      expect(entity.isRevoked, isFalse);
      expect(entity.openCount, 2);
      expect(entity.items.single.productId, 'product-1');
      expect(entity.items.single.imageUrl, 'https://img/1.png');
    });

    test('toEntity maps status "revoked" to isRevoked true', () {
      final dto = CatalogShareDto(
        id: 'share-1',
        organizationId: 'org-1',
        scope: 'product',
        items: const [
          CatalogShareItemDto(productId: 'product-1', name: 'Camisa'),
        ],
        status: 'revoked',
        openCount: 0,
        expiresAt: DateTime.utc(2026, 2, 1),
        createdBy: 'rep-1',
        createdByName: 'Rep Um',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );

      expect(mapper.toEntity(dto).isRevoked, isTrue);
    });

    test('scopeToEntity throws ValidationException for an unknown scope', () {
      expect(
        () => mapper.scopeToEntity('not-a-scope'),
        throwsA(isA<ValidationException>()),
      );
    });

    test(
      'outcomeToEntity throws ValidationException for an unknown outcome',
      () {
        expect(
          () => mapper.outcomeToEntity('not-an-outcome'),
          throwsA(isA<ValidationException>()),
        );
      },
    );

    test('previewToEntity maps a valid preview with items', () {
      final dto = CatalogSharePreviewDto(
        outcome: 'valid',
        organizationName: 'Grupo Fashion XPTO',
        scope: 'product',
        items: const [
          CatalogShareItemDto(productId: 'product-1', name: 'Camisa'),
        ],
        collectionName: null,
        expiresAt: DateTime.utc(2026, 2, 1),
      );

      final entity = mapper.previewToEntity(dto);

      expect(entity.outcome, CatalogShareOutcome.valid);
      expect(entity.organizationName, 'Grupo Fashion XPTO');
      expect(entity.scope, CatalogShareScope.product);
      expect(entity.items, hasLength(1));
    });

    test('previewToEntity maps an unavailable outcome with a null scope', () {
      const dto = CatalogSharePreviewDto(outcome: 'expired', items: []);

      final entity = mapper.previewToEntity(dto);

      expect(entity.outcome, CatalogShareOutcome.expired);
      expect(entity.scope, isNull);
      expect(entity.items, isEmpty);
    });
  });
}
