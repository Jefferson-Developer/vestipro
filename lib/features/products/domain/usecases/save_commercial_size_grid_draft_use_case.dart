import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/commercial_size_grid_draft.dart';
import '../repositories/commercial_size_grid_draft_repository.dart';

@injectable
final class SaveCommercialSizeGridDraftUseCase {
  const SaveCommercialSizeGridDraftUseCase(this._repository);

  final CommercialSizeGridDraftRepository _repository;

  Future<AppResult<CommercialSizeGridDraft>> call({
    required CommercialSizeGridDraft draft,
  }) {
    final fieldErrors = <String, String>{};
    if (draft.organizationId.trim().isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (draft.productId.trim().isEmpty) {
      fieldErrors['productId'] = 'ProductId is required.';
    }
    final invalidQuantity = draft.quantitiesByVariantId.entries
        .where((entry) => entry.key.trim().isEmpty || entry.value < 0)
        .isNotEmpty;
    if (invalidQuantity) {
      fieldErrors['quantitiesByVariantId'] =
          'Quantities must use valid variant ids and non-negative values.';
    }
    if (fieldErrors.isNotEmpty) {
      return Future.value(
        AppFailure<CommercialSizeGridDraft>(
          ValidationFailure(
            'Invalid commercial size grid draft payload.',
            fieldErrors: fieldErrors,
            code: 'invalid_commercial_size_grid_draft_payload',
          ),
        ),
      );
    }
    final sanitized = CommercialSizeGridDraft(
      organizationId: draft.organizationId.trim(),
      productId: draft.productId.trim(),
      quantitiesByVariantId: Map<String, int>.unmodifiable(
        Map<String, int>.fromEntries(
          draft.quantitiesByVariantId.entries.where(
            (entry) => entry.key.trim().isNotEmpty && entry.value > 0,
          ),
        ),
      ),
      updatedAt: draft.updatedAt.toUtc(),
    );
    return _repository.saveDraft(draft: sanitized);
  }
}
