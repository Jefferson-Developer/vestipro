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
    if (index == -1) {
      return const AppFailure<Category>(
        NotFoundFailure('Category not found.', code: 'category_not_found'),
      );
    }
    categories[index] = category;
    return AppSuccess<Category>(category);
  }

  @override
  Future<AppResult<List<Category>>> listByOrganization(
    String organizationId,
  ) async {
    return AppSuccess<List<Category>>(
      categories
          .where(
            (category) =>
                category.organizationId == organizationId &&
                category.deletedAt == null,
          )
          .toList(),
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
  }) async => AppSuccess<bool>(categoriesWithProducts.contains(categoryId));

  @override
  Future<AppResult<Category>> delete({
    required String organizationId,
    required String id,
    required String deletedBy,
  }) async {
    final index = categories.indexWhere((item) => item.id == id);
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
  }) async {
    final updated = <Category>[];
    for (var index = 0; index < orderedIds.length; index++) {
      final itemIndex = categories.indexWhere(
        (item) => item.id == orderedIds[index],
      );
      final reordered = categories[itemIndex].copyWith(sortOrder: index);
      categories[itemIndex] = reordered;
      updated.add(reordered);
    }
    return AppSuccess<List<Category>>(updated);
  }
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
  group('CreateCategoryUseCase', () {
    late _InMemoryCategoryRepository repository;
    late CreateCategoryUseCase useCase;

    setUp(() {
      repository = _InMemoryCategoryRepository();
      useCase = CreateCategoryUseCase(repository);
    });

    test('creates a root category with the trimmed name', () async {
      final result = await useCase.call(
        id: 'cat-1',
        organizationId: 'org-1',
        name: '  Feminino  ',
        createdBy: 'user-1',
      );

      expect(result, isA<AppSuccess<Category>>());
      final category = (result as AppSuccess<Category>).value;
      expect(category.name, 'Feminino');
      expect(category.parentId, isNull);
      expect(category.sortOrder, 0);
    });

    test('appends a new sibling at the end of the sort order', () async {
      repository.seed(_category(id: 'existing', sortOrder: 0));

      final result = await useCase.call(
        id: 'cat-2',
        organizationId: 'org-1',
        name: 'Masculino',
        createdBy: 'user-1',
      );

      expect((result as AppSuccess<Category>).value.sortOrder, 1);
    });

    test('rejects a blank name without touching the repository', () async {
      final result = await useCase.call(
        id: 'cat-1',
        organizationId: 'org-1',
        name: '   ',
        createdBy: 'user-1',
      );

      expect(result, isA<AppFailure<Category>>());
      expect(repository.categories, isEmpty);
    });

    test('rejects a parentId that does not exist', () async {
      final result = await useCase.call(
        id: 'cat-1',
        organizationId: 'org-1',
        name: 'Calças',
        parentId: 'missing-parent',
        createdBy: 'user-1',
      );

      expect(result, isA<AppFailure<Category>>());
      final failure = (result as AppFailure<Category>).failure;
      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).code, 'category_parent_not_found');
    });

    test('blocks a duplicate name among the same siblings', () async {
      repository.seed(_category(id: 'existing', parentId: 'root'));
      repository.seed(_category(id: 'root'));

      final result = await useCase.call(
        id: 'cat-2',
        organizationId: 'org-1',
        name: ' Existing ',
        parentId: 'root',
        createdBy: 'user-1',
      );

      expect(result, isA<AppFailure<Category>>());
      expect((result as AppFailure<Category>).failure, isA<ConflictFailure>());
    });

    test('allows the same name in a different sibling group', () async {
      repository.seed(_category(id: 'root-a'));
      repository.seed(_category(id: 'root-b'));
      repository.seed(_category(id: 'existing', parentId: 'root-a'));

      final result = await useCase.call(
        id: 'cat-2',
        organizationId: 'org-1',
        name: 'Existing',
        parentId: 'root-b',
        createdBy: 'user-1',
      );

      expect(result, isA<AppSuccess<Category>>());
    });
  });
}
