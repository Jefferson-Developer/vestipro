import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../repositories/product_import_template_repository.dart';

@injectable
final class DeleteProductImportTemplateUseCase {
  const DeleteProductImportTemplateUseCase(this._repository);

  final ProductImportTemplateRepository _repository;

  Future<AppResult<void>> call({
    required String organizationId,
    required String id,
  }) {
    return _repository.delete(organizationId: organizationId, id: id);
  }
}
