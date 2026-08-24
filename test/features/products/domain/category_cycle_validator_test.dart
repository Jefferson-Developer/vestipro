import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/products/products.dart';

Category _category({
  required String id,
  String? parentId,
  String organizationId = 'org-1',
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Category(
    id: id,
    organizationId: organizationId,
    name: id,
    parentId: parentId,
    sortOrder: 0,
    version: 1,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
  );
}

void main() {
  group('CategoryCycleValidator', () {
    test('moving to the root level never cycles', () {
      final categories = <Category>[_category(id: 'a')];

      expect(
        CategoryCycleValidator.wouldCreateCycle(
          categories: categories,
          categoryId: 'a',
          newParentId: null,
        ),
        isFalse,
      );
    });

    test('a category cannot become its own parent', () {
      final categories = <Category>[_category(id: 'a')];

      expect(
        CategoryCycleValidator.wouldCreateCycle(
          categories: categories,
          categoryId: 'a',
          newParentId: 'a',
        ),
        isTrue,
      );
    });

    test('a category cannot become a subcategory of its own descendant', () {
      // a -> b -> c
      final categories = <Category>[
        _category(id: 'a'),
        _category(id: 'b', parentId: 'a'),
        _category(id: 'c', parentId: 'b'),
      ];

      expect(
        CategoryCycleValidator.wouldCreateCycle(
          categories: categories,
          categoryId: 'a',
          newParentId: 'c',
        ),
        isTrue,
      );
      expect(
        CategoryCycleValidator.wouldCreateCycle(
          categories: categories,
          categoryId: 'b',
          newParentId: 'c',
        ),
        isTrue,
      );
    });

    test('moving to an unrelated branch never cycles', () {
      // a -> b, and a separate root d
      final categories = <Category>[
        _category(id: 'a'),
        _category(id: 'b', parentId: 'a'),
        _category(id: 'd'),
      ];

      expect(
        CategoryCycleValidator.wouldCreateCycle(
          categories: categories,
          categoryId: 'b',
          newParentId: 'd',
        ),
        isFalse,
      );
    });

    test('defensively stops instead of looping on pre-existing bad data', () {
      // a corrupted pair pointing at each other.
      final categories = <Category>[
        _category(id: 'a', parentId: 'b'),
        _category(id: 'b', parentId: 'a'),
      ];

      expect(
        CategoryCycleValidator.wouldCreateCycle(
          categories: categories,
          categoryId: 'c',
          newParentId: 'a',
        ),
        isTrue,
      );
    });
  });
}
