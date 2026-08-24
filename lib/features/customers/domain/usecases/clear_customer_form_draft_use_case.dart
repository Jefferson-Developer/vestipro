import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../repositories/customer_form_draft_repository.dart';

@injectable
final class ClearCustomerFormDraftUseCase {
  const ClearCustomerFormDraftUseCase(this._repository);

  final CustomerFormDraftRepository _repository;

  Future<AppResult<void>> call({
    required String organizationId,
    required String userId,
  }) {
    if (organizationId.trim().isEmpty || userId.trim().isEmpty) {
      return Future<AppResult<void>>.value(
        const AppFailure<void>(
          ValidationFailure(
            'Organization id and user id are required.',
            code: 'invalid_customer_draft_clear',
          ),
        ),
      );
    }

    return _repository.clear(
      organizationId: organizationId.trim(),
      userId: userId.trim(),
    );
  }
}
