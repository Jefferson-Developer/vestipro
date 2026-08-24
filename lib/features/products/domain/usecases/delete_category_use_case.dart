import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';

/// Soft-deletes a `Category` (TASK-067).
///
/// Never leaves a Product pointing at a deleted category, nor a
/// subcategory pointing at a deleted parent: blocked (`ConflictFailure`)
/// when the Category still has non-deleted children (code
/// `category_has_children`, requiring an explicit reallocation/deletion of
/// the children first) or when any non-deleted Product still references it
/// as `categoryId`/`subcategoryId` (code `category_in_use`, the same
/// "block, never orphan silently" rule `DeleteSeasonUseCase` applies to
/// Season).
@injectable
final class DeleteCategoryUseCase {
  DeleteCategoryUseCase(this._repository);

  final CategoryRepository _repository;

  Future<AppResult<Category>> call({
    required String organizationId,
    required String id,
    required String deletedBy,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedId = id.trim();
    final trimmedDeletedBy = deletedBy.trim();

    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedDeletedBy.isEmpty) {
      fieldErrors['deletedBy'] = 'DeletedBy is required.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<Category>(
        ValidationFailure(
          'Invalid category delete payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_category_delete_payload',
        ),
      );
    }

    final allResult = await _repository.listByOrganization(
      trimmedOrganizationId,
    );
    if (allResult is AppFailure<List<Category>>) {
      return AppFailure<Category>(allResult.failure);
    }
    final hasChildren = (allResult as AppSuccess<List<Category>>).value.any(
      (category) => category.parentId == trimmedId,
    );
    if (hasChildren) {
      return const AppFailure<Category>(
        ConflictFailure(
          'Esta categoria possui subcategorias vinculadas e não pode ser '
          'excluída. Realoque ou exclua as subcategorias primeiro.',
          code: 'category_has_children',
        ),
      );
    }

    final hasProductsResult = await _repository.hasProducts(
      organizationId: trimmedOrganizationId,
      categoryId: trimmedId,
    );
    if (hasProductsResult is AppFailure<bool>) {
      return AppFailure<Category>(hasProductsResult.failure);
    }
    if ((hasProductsResult as AppSuccess<bool>).value) {
      return const AppFailure<Category>(
        ConflictFailure(
          'Esta categoria está em uso por um ou mais produtos e não pode '
          'ser excluída.',
          code: 'category_in_use',
        ),
      );
    }

    return _repository.delete(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
      deletedBy: trimmedDeletedBy,
    );
  }
}
