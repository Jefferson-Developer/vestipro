import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../repositories/customer_import_template_repository.dart';

@injectable
final class DeleteCustomerImportTemplateUseCase {
  DeleteCustomerImportTemplateUseCase(this._repository);

  final CustomerImportTemplateRepository _repository;

  Future<AppResult<void>> call({
    required String organizationId,
    required String id,
  }) {
    return _repository.delete(organizationId: organizationId, id: id);
  }
}
