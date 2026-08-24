import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/products/products.dart';

class _InMemoryCategoryRepository implements CategoryRepository {
  final List<Category> categories = <Category>[];
  List<String>? lastReorderedIds;
  String? lastReorderedParentId;

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
  }) async {
    lastReorderedParentId = parentId;
    lastReorderedIds = orderedIds;
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

Category _category({required String id, String? parentId, int sortOrder = 0}) {
  final now = DateTime.utc(2026, 1, 1);
  return Category(
    id: id,
    organizationId: 'org-1',
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
  group('ReorderCategoriesUseCase', () {
    late _InMemoryCategoryRepository repository;
    late ReorderCategoriesUseCase useCase;

    setUp(() {
      repository = _InMemoryCategoryRepository();
      useCase = ReorderCategoriesUseCase(repository);
      repository.seed(_category(id: 'a', sortOrder: 0));
      repository.seed(_category(id: 'b', sortOrder: 1));
      repository.seed(_category(id: 'c', sortOrder: 2));
    });

    test('persists the full new sibling order', () async {
      final result = await useCase.call(
        organizationId: 'org-1',
        parentId: null,
        orderedIds: <String>['c', 'a', 'b'],
        updatedBy: 'user-2',
      );

      expect(result, isA<AppSuccess<List<Category>>>());
      expect(repository.lastReorderedIds, <String>['c', 'a', 'b']);
    });

    test('rejects a reorder that drops a sibling from the group', () async {
      final result = await useCase.call(
        organizationId: 'org-1',
        parentId: null,
        orderedIds: <String>['a', 'b'],
        updatedBy: 'user-2',
      );

      expect(result, isA<AppFailure<List<Category>>>());
      expect(
        (result as AppFailure<List<Category>>).failure,
        isA<ValidationFailure>(),
      );
      expect(repository.lastReorderedIds, isNull);
    });

    test('rejects a reorder that includes a category from another parent — '
        'reordering never silently reparents', () async {
      repository.seed(_category(id: 'outsider', parentId: 'a'));

      final result = await useCase.call(
        organizationId: 'org-1',
        parentId: null,
        orderedIds: <String>['a', 'b', 'c', 'outsider'],
        updatedBy: 'user-2',
      );

      expect(result, isA<AppFailure<List<Category>>>());
      expect(repository.lastReorderedIds, isNull);
    });
  });
}
