import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/customer_form_draft.dart';
import '../repositories/customer_form_draft_repository.dart';

@injectable
final class SaveCustomerFormDraftUseCase {
  const SaveCustomerFormDraftUseCase(this._repository);

  final CustomerFormDraftRepository _repository;

  Future<AppResult<void>> call(CustomerFormDraft draft) {
    return _repository.save(draft);
  }
}
