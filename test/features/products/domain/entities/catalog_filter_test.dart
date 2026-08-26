import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('CatalogFilter', () {
    test('empty filter has no active dimensions', () {
      expect(CatalogFilter.empty.isEmpty, isTrue);
      expect(CatalogFilter.empty.activeCount, 0);
    });

    test('activeCount counts single-valued and set-valued dimensions', () {
      const filter = CatalogFilter(
        collectionId: 'col-1',
        brand: 'Malwee',
        colorIds: <String>{'red', 'blue'},
        tags: <String>{'casual'},
        launchOnly: true,
      );

      expect(filter.isEmpty, isFalse);
      expect(filter.activeCount, 6);
    });

    test('normalized trims strings and drops blank set entries', () {
      const filter = CatalogFilter(
        collectionId: '  col-1  ',
        brand: '  ',
        colorIds: <String>{' red ', ''},
      );

      final normalized = filter.normalized();

      expect(normalized.collectionId, 'col-1');
      expect(normalized.brand, isNull);
      expect(normalized.colorIds, <String>{'red'});
    });

    test('copyWith replaces only the requested fields', () {
      const filter = CatalogFilter(collectionId: 'col-1', brand: 'Malwee');

      final updated = filter.copyWith(brand: 'Outra');

      expect(updated.collectionId, 'col-1');
      expect(updated.brand, 'Outra');
    });

    test('copyWith clear flags remove a single-valued dimension', () {
      const filter = CatalogFilter(collectionId: 'col-1');

      final cleared = filter.copyWith(clearCollectionId: true);

      expect(cleared.collectionId, isNull);
      expect(cleared.isEmpty, isTrue);
    });

    group('removing (chip removal)', () {
      test('clears a single-valued dimension entirely', () {
        const filter = CatalogFilter(seasonId: 'season-1', launchOnly: true);

        final withoutSeason = filter.removing(CatalogFilterKey.season);

        expect(withoutSeason.seasonId, isNull);
        expect(withoutSeason.launchOnly, isTrue);
      });

      test('drops only the one value from a set-valued dimension', () {
        const filter = CatalogFilter(colorIds: <String>{'red', 'blue'});

        final withoutRed = filter.removing(
          CatalogFilterKey.color,
          value: 'red',
        );

        expect(withoutRed.colorIds, <String>{'blue'});
      });

      test('removing "launch" turns launchOnly back off', () {
        const filter = CatalogFilter(launchOnly: true);

        final result = filter.removing(CatalogFilterKey.launch);

        expect(result.launchOnly, isFalse);
      });
    });

    group('query parameters round-trip', () {
      test('empty filter serializes to no parameters', () {
        expect(CatalogFilter.empty.toQueryParameters(), isEmpty);
      });

      test('every dimension survives a to/from round-trip', () {
        const filter = CatalogFilter(
          collectionId: 'col-1',
          seasonId: 'season-1',
          brand: 'Malwee',
          categoryId: 'cat-1',
          colorIds: <String>{'red', 'blue'},
          sizes: <String>{'P', 'M'},
          availability: VariantAvailabilityStatus.readyStock,
          launchOnly: true,
          tags: <String>{'casual', 'oferta'},
          material: 'algodão',
        );

        final restored = CatalogFilter.fromQueryParameters(
          filter.toQueryParameters(),
        );

        expect(restored, filter);
      });

      test('unknown/garbage availability code is ignored, not thrown', () {
        final restored = CatalogFilter.fromQueryParameters(<String, String>{
          'availability': 'not-a-real-status',
        });

        expect(restored.availability, isNull);
      });
    });

    group('matches', () {
      test('true for a fully empty filter, any product', () {
        expect(CatalogFilter.empty.matches(_product()), isTrue);
      });

      test('collectionId must match exactly', () {
        const filter = CatalogFilter(collectionId: 'col-1');
        expect(filter.matches(_product(collectionId: 'col-1')), isTrue);
        expect(filter.matches(_product(collectionId: 'col-2')), isFalse);
      });

      test('categoryId matches either categoryId or subcategoryId', () {
        const filter = CatalogFilter(categoryId: 'cat-1');
        expect(filter.matches(_product(categoryId: 'cat-1')), isTrue);
        expect(filter.matches(_product(subcategoryId: 'cat-1')), isTrue);
        expect(filter.matches(_product(categoryId: 'cat-2')), isFalse);
      });

      test('brand compares case-insensitively', () {
        const filter = CatalogFilter(brand: 'malwee');
        expect(filter.matches(_product(brand: 'Malwee')), isTrue);
        expect(filter.matches(_product(brand: 'Outra')), isFalse);
        expect(filter.matches(_product()), isFalse);
      });

      test('colorIds matches when any color intersects', () {
        const filter = CatalogFilter(colorIds: <String>{'red', 'blue'});
        expect(
          filter.matches(_product(colorIds: <String>['blue', 'green'])),
          isTrue,
        );
        expect(filter.matches(_product(colorIds: <String>['green'])), isFalse);
      });

      test('tags matches when any tag intersects', () {
        const filter = CatalogFilter(tags: <String>{'oferta'});
        expect(
          filter.matches(_product(tags: <String>['oferta', 'novo'])),
          isTrue,
        );
        expect(filter.matches(_product(tags: <String>['novo'])), isFalse);
      });

      test(
        'material matches Product.fabric as a case-insensitive substring',
        () {
          const filter = CatalogFilter(material: 'algodão');
          expect(filter.matches(_product(fabric: 'Algodão Pima')), isTrue);
          expect(filter.matches(_product(fabric: 'Poliéster')), isFalse);
          expect(filter.matches(_product()), isFalse);
        },
      );

      test('launchOnly requires a non-null launchDate', () {
        const filter = CatalogFilter(launchOnly: true);
        expect(
          filter.matches(_product(launchDate: DateTime.utc(2026, 1, 1))),
          isTrue,
        );
        expect(filter.matches(_product()), isFalse);
      });

      test('never inspects availability or sizes (documented limitation)', () {
        // These dimensions need data outside `Product` (availability,
        // size-grid templates) and are deliberately excluded from `matches`
        // — see the class doc. A filter that only sets them matches every
        // product from this method's point of view; the caller narrows
        // further after fetching.
        const filter = CatalogFilter(
          availability: VariantAvailabilityStatus.readyStock,
          sizes: <String>{'M'},
        );
        expect(filter.matches(_product()), isTrue);
      });
    });

    test('equality/hashCode ignore set ordering', () {
      const first = CatalogFilter(colorIds: <String>{'red', 'blue'});
      const second = CatalogFilter(colorIds: <String>{'blue', 'red'});

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });
  });
}

Product _product({
  String? collectionId,
  String? seasonId,
  String? brand,
  String? categoryId,
  String? subcategoryId,
  List<String> colorIds = const <String>[],
  List<String> tags = const <String>[],
  String? fabric,
  DateTime? launchDate,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Product(
    id: 'product-1',
    organizationId: 'org-1',
    sku: Sku.parse('SKU-1'),
    reference: 'REF-1',
    name: 'Produto',
    collectionId: collectionId,
    seasonId: seasonId,
    brand: brand,
    categoryId: categoryId,
    subcategoryId: subcategoryId,
    colorIds: colorIds,
    tags: tags,
    fabric: fabric,
    launchDate: launchDate,
    status: ProductStatus.active,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: ProductSyncStatus.pending,
  );
}
