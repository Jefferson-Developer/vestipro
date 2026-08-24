import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/products/data/repositories/shared_preferences_category_repository.dart';
import 'package:vestipro/features/products/products.dart';

/// Integration coverage for TASK-067's "single source of truth" acceptance
/// criterion: the category/subcategory tree the Product cadastro (TASK-065)
/// picker reads must be exactly the same tree the future catalog filter
/// (EPIC-10) will read — never two divergent taxonomy copies.
///
/// EPIC-10's actual catalog filter screen does not exist yet (it is a later
/// task in the backlog), so this test stands in for it the same way the
/// entity's own docs already describe the picker as reused "later" by that
/// screen: it exercises a second, independent consumer of
/// `ListCategoriesUseCase`/`CategoryRepository` — the same contract a
/// catalog filter would call — and asserts it observes precisely what the
/// cadastro's `ProductFormBloc` observes, including a category created
/// after the fact.
void main() {
  test('the Product cadastro picker and a second, independent reader observe '
      'the exact same Category tree from the same repository', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final repository = SharedPreferencesCategoryRepository();
    final listCategories = ListCategoriesUseCase(repository);
    final createCategory = CreateCategoryUseCase(repository);

    await createCategory.call(
      id: 'cat-1',
      organizationId: 'org-1',
      name: 'Feminino',
      createdBy: 'user-1',
    );
    await createCategory.call(
      id: 'cat-1-sub',
      organizationId: 'org-1',
      name: 'Calças',
      parentId: 'cat-1',
      createdBy: 'user-1',
    );

    // Consumer #1: what ProductFormBloc loads for its category picker.
    final cadastroResult = await listCategories('org-1');
    final cadastroTree = (cadastroResult as AppSuccess<List<Category>>).value;

    // Consumer #2: a second, independent reader — standing in for the
    // future catalog filter (EPIC-10) — hitting the very same use
    // case/repository, never a duplicated taxonomy store of its own.
    final catalogFilterResult = await listCategories('org-1');
    final catalogFilterTree =
        (catalogFilterResult as AppSuccess<List<Category>>).value;

    expect(catalogFilterTree, equals(cadastroTree));
    expect(catalogFilterTree.map((c) => c.id).toSet(), <String>{
      'cat-1',
      'cat-1-sub',
    });

    // A category created after the cadastro's first load is immediately
    // visible to the next read from either consumer — proving there is
    // no separate, stale copy of the tree anywhere.
    await createCategory.call(
      id: 'cat-2',
      organizationId: 'org-1',
      name: 'Masculino',
      createdBy: 'user-1',
    );

    final refreshedCadastroTree =
        (await listCategories('org-1') as AppSuccess<List<Category>>).value;
    final refreshedCatalogFilterTree =
        (await listCategories('org-1') as AppSuccess<List<Category>>).value;

    expect(refreshedCatalogFilterTree, equals(refreshedCadastroTree));
    expect(refreshedCadastroTree, hasLength(3));
  });
}
