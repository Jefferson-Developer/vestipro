import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/products/products.dart';

class _InMemoryCategoryRepository implements CategoryRepository {
  final List<Category> categories = <Category>[];

  @override
  Future<AppResult<Category>> create({required Category category}) async {
    categories.add(category);
    return AppSuccess<Category>(category);
  }

  @override
  Future<AppResult<Category>> update({required Category category}) async =>
      AppSuccess<Category>(category);

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
  }) async => throw UnimplementedError();

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
  }) async => throw UnimplementedError();

  @override
  Future<AppResult<List<Category>>> reorder({
    required String organizationId,
    required String? parentId,
    required List<String> orderedIds,
    required String updatedBy,
  }) async => throw UnimplementedError();
}

Category _category({required String id, required int sortOrder}) {
  final now = DateTime.utc(2026, 1, 1);
  return Category(
    id: id,
    organizationId: 'org-1',
    name: id,
    sortOrder: sortOrder,
    version: 1,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
  );
}

void main() {
  test(
    'ListCategoriesUseCase sorts by manual sortOrder within a level',
    () async {
      final repository = _InMemoryCategoryRepository();
      repository.categories.addAll(<Category>[
        _category(id: 'c', sortOrder: 2),
        _category(id: 'a', sortOrder: 0),
        _category(id: 'b', sortOrder: 1),
      ]);
      final useCase = ListCategoriesUseCase(repository);

      final result = await useCase('org-1');

      expect(
        (result as AppSuccess<List<Category>>).value.map((c) => c.id),
        <String>['a', 'b', 'c'],
      );
    },
  );
}
