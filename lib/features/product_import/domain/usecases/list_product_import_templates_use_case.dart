import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/product_import_template.dart';
import '../repositories/product_import_template_repository.dart';

@injectable
final class ListProductImportTemplatesUseCase {
  const ListProductImportTemplatesUseCase(this._repository);

  final ProductImportTemplateRepository _repository;

  Future<AppResult<List<ProductImportTemplate>>> call({
    required String organizationId,
  }) {
    return _repository.listByOrganization(organizationId);
  }
}
