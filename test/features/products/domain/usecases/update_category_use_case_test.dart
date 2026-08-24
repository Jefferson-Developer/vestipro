import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/products/products.dart';

class _InMemoryCategoryRepository implements CategoryRepository {
  final List<Category> categories = <Category>[];

  void seed(Category category) => categories.add(category);

  @override
  Future<AppResult<Category>> create({required Category category}) async {
    categories.add(category);
    return AppSuccess<Category>(category);
  }

  @override
  Future<AppResult<Category>> update({required Category category}) async {
    final index = categories.indexWhere((item) => item.id == category.id);
    categories[index] = category;
    return AppSuccess<Category>(category);
  }

  @override
  Future<AppResult<List<Category>>> listByOrganization(
    String organizationId,
  ) async {
    return AppSuccess<List<Category>>(
      categories.where((category) => category.deletedAt == null).toList(),
    );
  }

  @override
  Future<AppResult<Category>> getById({
    required String organizationId,
    required String id,
  }) async {
    for (final category in categories) {
      if (category.id == id && category.deletedAt == null) {
        return AppSuccess<Category>(category);
      }
    }
    return const AppFailure<Category>(
      NotFoundFailure('Category not found.', code: 'category_not_found'),
    );
  }

  @override
  Future<AppResult<bool>> existsByName({
    required String organizationId,
    required String name,
    String? parentId,
    String? excludingCategoryId,
  }) async {
    final normalized = name.trim().toLowerCase();
    return AppSuccess<bool>(
      categories.any(
        (category) =>
            category.deletedAt == null &&
            category.parentId == parentId &&
            category.name.trim().toLowerCase() == normalized &&
            category.id != excludingCategoryId,
      ),
    );
  }

  @override
  Future<AppResult<bool>> hasProducts({
    required String organizationId,
    required String categoryId,
  }) async => const AppSuccess<bool>(false);

  @override
  Future<AppResult<Category>> delete({
    required String organizationId,
    required String id,
    required String deletedBy,
  }) async {
    final index = categories.indexWhere((item) => item.id == id);
    final deleted = categories[index].copyWith(
      deletedAt: DateTime.utc(2026, 1, 2),
    );
    categories[index] = deleted;
    return AppSuccess<Category>(deleted);
  }

  @override
  Future<AppResult<List<Category>>> reorder({
    required String organizationId,
    required String? parentId,
    required List<String> orderedIds,
    required String updatedBy,
  }) async => const AppSuccess<List<Category>>(<Category>[]);
}

Category _category({
  required String id,
  String? parentId,
  int sortOrder = 0,
  String organizationId = 'org-1',
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Category(
    id: id,
    organizationId: organizationId,
    name: id,
    parentId: parentId,
    sortOrder: sortOrder,
    version: 1,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
  );
}

void main() {
  group('UpdateCategoryUseCase', () {
    late _InMemoryCategoryRepository repository;
    late UpdateCategoryUseCase useCase;

    setUp(() {
      repository = _InMemoryCategoryRepository();
      useCase = UpdateCategoryUseCase(repository);
    });

    test('renames a category without touching its parent', () async {
      repository.seed(_category(id: 'cat-1'));

      final result = await useCase.call(
        organizationId: 'org-1',
        id: 'cat-1',
        name: ' Feminino ',
        parentId: null,
        updatedBy: 'user-2',
      );

      expect(result, isA<AppSuccess<Category>>());
      final category = (result as AppSuccess<Category>).value;
      expect(category.name, 'Feminino');
      expect(category.version, 2);
    });

    test('rejects a category becoming its own parent', () async {
      repository.seed(_category(id: 'cat-1'));

      final result = await useCase.call(
        organizationId: 'org-1',
        id: 'cat-1',
        name: 'cat-1',
        parentId: 'cat-1',
        updatedBy: 'user-2',
      );

      expect(result, isA<AppFailure<Category>>());
      expect(
        (result as AppFailure<Category>).failure,
        isA<ValidationFailure>(),
      );
    });

    test(
      'rejects moving a category under its own descendant (cycle)',
      () async {
        // a -> b -> c
        repository.seed(_category(id: 'a'));
        repository.seed(_category(id: 'b', parentId: 'a'));
        repository.seed(_category(id: 'c', parentId: 'b'));

        final result = await useCase.call(
          organizationId: 'org-1',
          id: 'a',
          name: 'a',
          parentId: 'c',
          updatedBy: 'user-2',
        );

        expect(result, isA<AppFailure<Category>>());
        expect(
          (result as AppFailure<Category>).failure,
          isA<ConflictFailure>(),
        );
        expect(
          ((result).failure as ConflictFailure).code,
          'category_cycle_detected',
        );
        // Never persisted the invalid move.
        expect(repository.categories.first.parentId, isNull);
      },
    );

    test('allows an explicit, non-cyclic move to a new parent', () async {
      repository.seed(_category(id: 'root-a'));
      repository.seed(_category(id: 'root-b'));
      repository.seed(_category(id: 'child', parentId: 'root-a'));

      final result = await useCase.call(
        organizationId: 'org-1',
        id: 'child',
        name: 'child',
        parentId: 'root-b',
        updatedBy: 'user-2',
      );

      expect(result, isA<AppSuccess<Category>>());
      expect((result as AppSuccess<Category>).value.parentId, 'root-b');
    });

    test('blocks a duplicate name in the destination sibling group', () async {
      repository.seed(_category(id: 'root'));
      repository.seed(_category(id: 'existing', parentId: 'root'));
      repository.seed(_category(id: 'moving'));

      final result = await useCase.call(
        organizationId: 'org-1',
        id: 'moving',
        name: 'existing',
        parentId: 'root',
        updatedBy: 'user-2',
      );

      expect(result, isA<AppFailure<Category>>());
      expect((result as AppFailure<Category>).failure, isA<ConflictFailure>());
    });
  });
}
