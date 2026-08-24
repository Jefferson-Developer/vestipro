import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';

/// Persists a manual sibling order for `Category` (TASK-067).
///
/// [orderedIds] must be exactly the current set of non-deleted siblings of
/// [parentId] — no missing id, no extra id, and every id must actually
/// belong to [parentId] today. This is what keeps a reorder drag-and-drop
/// (Web) or an explicit "mover para cima/baixo" action (mobile) from ever
/// silently reparenting a category: any attempt to reorder a category into
/// a different parent's sibling group is rejected instead of moving it —
/// reparenting only ever happens through the explicit
/// `UpdateCategoryUseCase` call.
@injectable
final class ReorderCategoriesUseCase {
  ReorderCategoriesUseCase(this._repository);

  final CategoryRepository _repository;

  Future<AppResult<List<Category>>> call({
    required String organizationId,
    required String? parentId,
    required List<String> orderedIds,
    required String updatedBy,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedUpdatedBy = updatedBy.trim();

    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedUpdatedBy.isEmpty) {
      fieldErrors['updatedBy'] = 'UpdatedBy is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<List<Category>>(
        ValidationFailure(
          'Invalid category reorder payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_category_reorder_payload',
        ),
      );
    }

    final allResult = await _repository.listByOrganization(
      trimmedOrganizationId,
    );
    if (allResult is AppFailure<List<Category>>) return allResult;
    final all = (allResult as AppSuccess<List<Category>>).value;

    final currentSiblingIds = all
        .where((category) => category.parentId == parentId)
        .map((category) => category.id)
        .toSet();
    final requestedIds = orderedIds.toSet();

    if (requestedIds.length != orderedIds.length ||
        requestedIds.length != currentSiblingIds.length ||
        !requestedIds.containsAll(currentSiblingIds)) {
      return const AppFailure<List<Category>>(
        ValidationFailure(
          'A reordenação deve incluir exatamente as categorias deste '
          'mesmo nível, sem mover nenhuma para fora dele.',
          code: 'category_reorder_set_mismatch',
        ),
      );
    }

    return _repository.reorder(
      organizationId: trimmedOrganizationId,
      parentId: parentId,
      orderedIds: orderedIds,
      updatedBy: trimmedUpdatedBy,
    );
  }
}
