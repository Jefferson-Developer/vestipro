import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/commercial_size_grid_draft.dart';
import '../repositories/commercial_size_grid_draft_repository.dart';

@injectable
final class GetCommercialSizeGridDraftUseCase {
  const GetCommercialSizeGridDraftUseCase(this._repository);

  final CommercialSizeGridDraftRepository _repository;

  Future<AppResult<CommercialSizeGridDraft?>> call({
    required String organizationId,
    required String productId,
  }) {
    final fieldErrors = <String, String>{};
    if (organizationId.trim().isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (productId.trim().isEmpty) {
      fieldErrors['productId'] = 'ProductId is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return Future.value(
        AppFailure<CommercialSizeGridDraft?>(
          ValidationFailure(
            'Invalid commercial size grid draft payload.',
            fieldErrors: fieldErrors,
            code: 'invalid_commercial_size_grid_draft_payload',
          ),
        ),
      );
    }
    return _repository.getDraft(
      organizationId: organizationId.trim(),
      productId: productId.trim(),
    );
  }
}
