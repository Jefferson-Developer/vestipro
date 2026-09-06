import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/customer_import_template.dart';
import '../repositories/customer_import_template_repository.dart';

@injectable
final class ListCustomerImportTemplatesUseCase {
  ListCustomerImportTemplatesUseCase(this._repository);

  final CustomerImportTemplateRepository _repository;

  Future<AppResult<List<CustomerImportTemplate>>> call({
    required String organizationId,
  }) {
    return _repository.listByOrganization(organizationId: organizationId);
  }
}
