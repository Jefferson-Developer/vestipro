import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';

/// Lists every non-deleted `Category` of an Organization (TASK-067), the
/// single source of truth reused both by the Product form's category/
/// subcategory pickers and, later, by the catalog filters (EPIC-10). Sorted
/// by manual [Category.sortOrder] (then name, for deterministic ties)
/// within each sibling group; grouping by [Category.parentId] into an
/// actual tree is left to the caller.
@injectable
final class ListCategoriesUseCase {
  ListCategoriesUseCase(this._repository);

  final CategoryRepository _repository;

  Future<AppResult<List<Category>>> call(String organizationId) async {
    final result = await _repository.listByOrganization(organizationId.trim());
    return result.fold(
      onSuccess: (categories) {
        final sorted = List<Category>.of(categories)
          ..sort((a, b) {
            final orderComparison = a.sortOrder.compareTo(b.sortOrder);
            if (orderComparison != 0) return orderComparison;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
        return AppSuccess<List<Category>>(sorted);
      },
      onFailure: AppFailure<List<Category>>.new,
    );
  }
}
