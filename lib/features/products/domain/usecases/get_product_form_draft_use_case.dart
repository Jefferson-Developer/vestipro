import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/product_form_draft.dart';
import '../repositories/product_form_draft_repository.dart';

@injectable
final class GetProductFormDraftUseCase {
  const GetProductFormDraftUseCase(this._repository);

  final ProductFormDraftRepository _repository;

  Future<AppResult<ProductFormDraft?>> call({
    required String organizationId,
    required String userId,
  }) {
    if (organizationId.trim().isEmpty || userId.trim().isEmpty) {
      return Future<AppResult<ProductFormDraft?>>.value(
        const AppFailure<ProductFormDraft?>(
          ValidationFailure(
            'Organization id and user id are required.',
            code: 'invalid_product_draft_lookup',
          ),
        ),
      );
    }

    return _repository.get(
      organizationId: organizationId.trim(),
      userId: userId.trim(),
    );
  }
}
