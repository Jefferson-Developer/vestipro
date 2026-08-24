import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../category_cycle_validator.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';

/// Renames and/or reparents an existing `Category` (TASK-067).
///
/// [parentId] is always required (`null` explicitly means "move to the
/// root level") so every call is an explicit statement of the desired
/// parent — reordering siblings never goes through this use case, only
/// through `ReorderCategoriesUseCase`.
///
/// Reparenting is rejected when it would make [id] its own ancestor
/// (`CategoryCycleValidator`) or when the new sibling group already has a
/// Category with the same trimmed, case-insensitive name.
@injectable
final class UpdateCategoryUseCase {
  UpdateCategoryUseCase(this._repository);

  final CategoryRepository _repository;

  Future<AppResult<Category>> call({
    required String organizationId,
    required String id,
    required String name,
    required String? parentId,
    required String updatedBy,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedId = id.trim();
    final trimmedName = name.trim();
    final trimmedParentId = parentId?.trim().isEmpty ?? true
        ? null
        : parentId!.trim();
    final trimmedUpdatedBy = updatedBy.trim();

    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedName.isEmpty) {
      fieldErrors['name'] = 'Informe o nome da categoria.';
    }
    if (trimmedUpdatedBy.isEmpty) {
      fieldErrors['updatedBy'] = 'UpdatedBy is required.';
    }
    if (trimmedParentId == trimmedId) {
      fieldErrors['parentId'] =
          'Uma categoria não pode ser subcategoria dela mesma.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<Category>(
        ValidationFailure(
          'Invalid category update payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_category_update_payload',
        ),
      );
    }

    final existingResult = await _repository.getById(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
    );
    if (existingResult is AppFailure<Category>) return existingResult;
    final existing = (existingResult as AppSuccess<Category>).value;

    final isMoving = trimmedParentId != existing.parentId;

    if (isMoving) {
      if (trimmedParentId != null) {
        final parentResult = await _repository.getById(
          organizationId: trimmedOrganizationId,
          id: trimmedParentId,
        );
        if (parentResult is AppFailure<Category>) {
          return const AppFailure<Category>(
            ValidationFailure(
              'A categoria pai selecionada não existe.',
              fieldErrors: <String, String>{
                'parentId': 'A categoria pai selecionada não existe.',
              },
              code: 'category_parent_not_found',
            ),
          );
        }
      }

      final allResult = await _repository.listByOrganization(
        trimmedOrganizationId,
      );
      if (allResult is AppFailure<List<Category>>) {
        return AppFailure<Category>(allResult.failure);
      }
      final all = (allResult as AppSuccess<List<Category>>).value;

      if (CategoryCycleValidator.wouldCreateCycle(
        categories: all,
        categoryId: trimmedId,
        newParentId: trimmedParentId,
      )) {
        return const AppFailure<Category>(
          ConflictFailure(
            'Esta categoria não pode se tornar subcategoria dela mesma '
            'nem de uma categoria descendente sua.',
            code: 'category_cycle_detected',
          ),
        );
      }
    }

    final duplicateResult = await _repository.existsByName(
      organizationId: trimmedOrganizationId,
      name: trimmedName,
      parentId: trimmedParentId,
      excludingCategoryId: trimmedId,
    );
    if (duplicateResult is AppFailure<bool>) {
      return AppFailure<Category>(duplicateResult.failure);
    }
    if ((duplicateResult as AppSuccess<bool>).value) {
      return const AppFailure<Category>(
        ConflictFailure(
          'Já existe uma categoria com esse nome neste nível.',
          code: 'category_name_already_exists',
        ),
      );
    }

    var nextSortOrder = existing.sortOrder;
    if (isMoving) {
      final siblingsResult = await _repository.listByOrganization(
        trimmedOrganizationId,
      );
      if (siblingsResult is AppFailure<List<Category>>) {
        return AppFailure<Category>(siblingsResult.failure);
      }
      nextSortOrder = (siblingsResult as AppSuccess<List<Category>>).value
          .where(
            (category) =>
                category.parentId == trimmedParentId &&
                category.id != trimmedId,
          )
          .length;
    }

    final updated = existing.copyWith(
      name: trimmedName,
      parentId: trimmedParentId,
      sortOrder: nextSortOrder,
      updatedAt: DateTime.now().toUtc(),
      updatedBy: trimmedUpdatedBy,
      version: existing.version + 1,
    );

    return _repository.update(category: updated);
  }
}
