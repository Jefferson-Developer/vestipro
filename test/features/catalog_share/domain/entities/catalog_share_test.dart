import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/catalog_share/catalog_share.dart';

void main() {
  group('CatalogShare.isActiveAt', () {
    CatalogShare buildShare({
      required bool isRevoked,
      required DateTime expiresAt,
    }) {
      return CatalogShare(
        id: 'share-1',
        organizationId: 'org-1',
        scope: CatalogShareScope.product,
        items: const [CatalogShareItem(productId: 'product-1', name: 'Camisa')],
        isRevoked: isRevoked,
        openCount: 0,
        expiresAt: expiresAt,
        createdBy: 'rep-1',
        createdByName: 'Rep Um',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
    }

    test('is active when not revoked and not yet expired', () {
      final share = buildShare(
        isRevoked: false,
        expiresAt: DateTime.utc(2026, 2, 1),
      );

      expect(share.isActiveAt(DateTime.utc(2026, 1, 15)), isTrue);
    });

    test('is not active once past expiresAt', () {
      final share = buildShare(
        isRevoked: false,
        expiresAt: DateTime.utc(2026, 1, 1),
      );

      expect(share.isActiveAt(DateTime.utc(2026, 1, 15)), isFalse);
    });

    test('is not active when revoked, even before expiresAt', () {
      final share = buildShare(
        isRevoked: true,
        expiresAt: DateTime.utc(2026, 2, 1),
      );

      expect(share.isActiveAt(DateTime.utc(2026, 1, 15)), isFalse);
    });
  });
}
