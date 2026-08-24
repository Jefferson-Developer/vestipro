import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/product_form_draft.dart';
import '../repositories/product_form_draft_repository.dart';

@injectable
final class SaveProductFormDraftUseCase {
  const SaveProductFormDraftUseCase(this._repository);

  final ProductFormDraftRepository _repository;

  Future<AppResult<void>> call(ProductFormDraft draft) {
    return _repository.save(draft);
  }
}
