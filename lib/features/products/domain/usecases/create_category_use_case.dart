import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';

/// Creates a new `Category`/subcategory tree entry (TASK-067).
///
/// [parentId], when provided, must reference an existing Category of the
/// same Organization (never validated on the client alone). Sibling names
/// (same [parentId]) are unique, case-insensitive and trimmed, mirroring
/// `CreateSeasonUseCase`'s duplicate-name guard. New entries are always
/// appended at the end of their sibling group — reordering is a separate,
/// explicit `ReorderCategoriesUseCase` call.
@injectable
final class CreateCategoryUseCase {
  CreateCategoryUseCase(this._repository);

  final CategoryRepository _repository;

  Future<AppResult<Category>> call({
    required String id,
    required String organizationId,
    required String name,
    String? parentId,
    required String createdBy,
  }) async {
    final trimmedId = id.trim();
    final trimmedOrganizationId = organizationId.trim();
    final trimmedName = name.trim();
    final trimmedParentId = parentId?.trim().isEmpty ?? true
        ? null
        : parentId!.trim();
    final trimmedCreatedBy = createdBy.trim();

    final fieldErrors = <String, String>{};
    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedName.isEmpty) {
      fieldErrors['name'] = 'Informe o nome da categoria.';
    }
    if (trimmedCreatedBy.isEmpty) {
      fieldErrors['createdBy'] = 'CreatedBy is required.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<Category>(
        ValidationFailure(
          'Invalid category creation payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_category_create_payload',
        ),
      );
    }

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

    final duplicateResult = await _repository.existsByName(
      organizationId: trimmedOrganizationId,
      name: trimmedName,
      parentId: trimmedParentId,
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

    final siblingsResult = await _repository.listByOrganization(
      trimmedOrganizationId,
    );
    if (siblingsResult is AppFailure<List<Category>>) {
      return AppFailure<Category>(siblingsResult.failure);
    }
    final siblingCount = (siblingsResult as AppSuccess<List<Category>>).value
        .where((category) => category.parentId == trimmedParentId)
        .length;

    final now = DateTime.now().toUtc();
    final category = Category(
      id: trimmedId,
      organizationId: trimmedOrganizationId,
      name: trimmedName,
      parentId: trimmedParentId,
      sortOrder: siblingCount,
      version: 1,
      createdAt: now,
      createdBy: trimmedCreatedBy,
      updatedAt: now,
      updatedBy: trimmedCreatedBy,
    );

    return _repository.create(category: category);
  }
}
