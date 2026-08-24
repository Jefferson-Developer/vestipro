import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/customer_form_draft.dart';
import '../repositories/customer_form_draft_repository.dart';

@injectable
final class GetCustomerFormDraftUseCase {
  const GetCustomerFormDraftUseCase(this._repository);

  final CustomerFormDraftRepository _repository;

  Future<AppResult<CustomerFormDraft?>> call({
    required String organizationId,
    required String userId,
  }) {
    if (organizationId.trim().isEmpty || userId.trim().isEmpty) {
      return Future<AppResult<CustomerFormDraft?>>.value(
        const AppFailure<CustomerFormDraft?>(
          ValidationFailure(
            'Organization id and user id are required.',
            code: 'invalid_customer_draft_lookup',
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
