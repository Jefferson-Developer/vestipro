import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/products/products.dart';

class _InMemoryCategoryRepository implements CategoryRepository {
  final List<Category> categories = <Category>[];
  final Set<String> categoriesWithProducts = <String>{};

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
      if (category.id == id) return AppSuccess<Category>(category);
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
  }) async => const AppSuccess<bool>(false);

  @override
  Future<AppResult<bool>> hasProducts({
    required String organizationId,
    required String categoryId,
  }) async => AppSuccess<bool>(categoriesWithProducts.contains(categoryId));

  @override
  Future<AppResult<Category>> delete({
    required String organizationId,
    required String id,
    required String deletedBy,
  }) async {
    final index = categories.indexWhere((item) => item.id == id);
    if (index == -1) {
      return const AppFailure<Category>(
        NotFoundFailure('Category not found.', code: 'category_not_found'),
      );
    }
    final deleted = categories[index].copyWith(
      deletedAt: DateTime.utc(2026, 1, 2),
      updatedBy: deletedBy,
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

Category _category({required String id, String? parentId}) {
  final now = DateTime.utc(2026, 1, 1);
  return Category(
    id: id,
    organizationId: 'org-1',
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
  group('DeleteCategoryUseCase', () {
    late _InMemoryCategoryRepository repository;
    late DeleteCategoryUseCase useCase;

    setUp(() {
      repository = _InMemoryCategoryRepository();
      useCase = DeleteCategoryUseCase(repository);
    });

    test(
      'soft-deletes a leaf category with no subcategories or products',
      () async {
        repository.seed(_category(id: 'cat-1'));

        final result = await useCase.call(
          organizationId: 'org-1',
          id: 'cat-1',
          deletedBy: 'user-2',
        );

        expect(result, isA<AppSuccess<Category>>());
        expect((result as AppSuccess<Category>).value.deletedAt, isNotNull);
      },
    );

    test('blocks deletion when the category still has subcategories', () async {
      repository.seed(_category(id: 'cat-1'));
      repository.seed(_category(id: 'cat-1-sub', parentId: 'cat-1'));

      final result = await useCase.call(
        organizationId: 'org-1',
        id: 'cat-1',
        deletedBy: 'user-2',
      );

      expect(result, isA<AppFailure<Category>>());
      final failure = (result as AppFailure<Category>).failure;
      expect(failure, isA<ConflictFailure>());
      expect((failure as ConflictFailure).code, 'category_has_children');
      // Never soft-deleted despite the blocked attempt.
      expect(repository.categories.first.deletedAt, isNull);
    });

    test('blocks deletion when a Product still references the category — '
        'never orphans a Product silently', () async {
      repository.seed(_category(id: 'cat-1'));
      repository.categoriesWithProducts.add('cat-1');

      final result = await useCase.call(
        organizationId: 'org-1',
        id: 'cat-1',
        deletedBy: 'user-2',
      );

      expect(result, isA<AppFailure<Category>>());
      final failure = (result as AppFailure<Category>).failure;
      expect(failure, isA<ConflictFailure>());
      expect((failure as ConflictFailure).code, 'category_in_use');
      expect(repository.categories.first.deletedAt, isNull);
    });
  });
}
