import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/products/data/repositories/shared_preferences_category_repository.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('SharedPreferencesCategoryRepository', () {
    late SharedPreferencesCategoryRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      repository = const SharedPreferencesCategoryRepository();
    });

    test('persists a created category and reads it back', () async {
      final createResult = await repository.create(category: _category());
      final lookupResult = await repository.getById(
        organizationId: 'org-1',
        id: 'cat-1',
      );

      expect(createResult, isA<AppSuccess<Category>>());
      expect((lookupResult as AppSuccess<Category>).value.name, 'Feminino');
    });

    test(
      'existsByName is scoped to the same parent, case-insensitive',
      () async {
        await repository.create(category: _category());
        await repository.create(
          category: _category(
            id: 'cat-2',
            name: 'Masculino',
            parentId: 'other-root',
          ),
        );

        final sameLevel = await repository.existsByName(
          organizationId: 'org-1',
          name: '  FEMININO  ',
        );
        final differentLevel = await repository.existsByName(
          organizationId: 'org-1',
          name: 'Feminino',
          parentId: 'other-root',
        );

        expect((sameLevel as AppSuccess<bool>).value, isTrue);
        expect((differentLevel as AppSuccess<bool>).value, isFalse);
      },
    );

    test('existsByName excludes the category being edited', () async {
      await repository.create(category: _category());

      final result = await repository.existsByName(
        organizationId: 'org-1',
        name: 'Feminino',
        excludingCategoryId: 'cat-1',
      );

      expect((result as AppSuccess<bool>).value, isFalse);
    });

    test(
      'delete soft-deletes and excludes it from listByOrganization',
      () async {
        await repository.create(category: _category());

        final deleteResult = await repository.delete(
          organizationId: 'org-1',
          id: 'cat-1',
          deletedBy: 'user-2',
        );
        final listResult = await repository.listByOrganization('org-1');

        expect(deleteResult, isA<AppSuccess<Category>>());
        expect((listResult as AppSuccess<List<Category>>).value, isEmpty);
      },
    );

    test('listByOrganization isolates by organization', () async {
      await repository.create(category: _category());
      await repository.create(category: _category(organizationId: 'org-2'));

      final result = await repository.listByOrganization('org-1');

      expect((result as AppSuccess<List<Category>>).value, hasLength(1));
    });

    test('reorder persists a new sortOrder for each sibling', () async {
      await repository.create(category: _category(id: 'a', sortOrder: 0));
      await repository.create(category: _category(id: 'b', sortOrder: 1));

      final result = await repository.reorder(
        organizationId: 'org-1',
        parentId: null,
        orderedIds: <String>['b', 'a'],
        updatedBy: 'user-2',
      );

      expect(result, isA<AppSuccess<List<Category>>>());
      final reordered = (result as AppSuccess<List<Category>>).value;
      expect(reordered.map((c) => c.id).toList(), <String>['b', 'a']);
      expect(reordered.first.sortOrder, 0);
      expect(reordered.last.sortOrder, 1);
    });

    test('hasProducts reflects the usage index a Product repository would '
        'write, defaulting to false when nothing was ever written', () async {
      final result = await repository.hasProducts(
        organizationId: 'org-1',
        categoryId: 'cat-1',
      );

      expect((result as AppSuccess<bool>).value, isFalse);
    });
  });
}

Category _category({
  String id = 'cat-1',
  String name = 'Feminino',
  String? parentId,
  int sortOrder = 0,
  String organizationId = 'org-1',
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Category(
    id: id,
    organizationId: organizationId,
    name: name,
    parentId: parentId,
    sortOrder: sortOrder,
    version: 1,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
  );
}
