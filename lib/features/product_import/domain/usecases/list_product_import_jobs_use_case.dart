import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/product_import_job.dart';
import '../repositories/product_import_job_repository.dart';

@injectable
final class ListProductImportJobsUseCase {
  const ListProductImportJobsUseCase(this._repository);

  final ProductImportJobRepository _repository;

  Future<AppResult<List<ProductImportJob>>> call({
    required String organizationId,
    int limit = 20,
  }) {
    return _repository.listByOrganization(
      organizationId: organizationId,
      limit: limit,
    );
  }
}
