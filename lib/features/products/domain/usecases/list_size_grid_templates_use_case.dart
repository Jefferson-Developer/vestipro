import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/size_grid_template.dart';
import '../repositories/size_grid_template_repository.dart';

@injectable
final class ListSizeGridTemplatesUseCase {
  const ListSizeGridTemplatesUseCase(this._repository);

  final SizeGridTemplateRepository _repository;

  Future<AppResult<List<SizeGridTemplate>>> call(String organizationId) {
    return _repository.listByOrganization(organizationId.trim());
  }
}
