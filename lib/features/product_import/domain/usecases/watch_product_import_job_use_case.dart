import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/product_import_job.dart';
import '../repositories/product_import_job_repository.dart';

@injectable
final class WatchProductImportJobUseCase {
  const WatchProductImportJobUseCase(this._repository);

  final ProductImportJobRepository _repository;

  Stream<AppResult<ProductImportJob>> call({
    required String organizationId,
    required String jobId,
  }) {
    return _repository.watchJob(organizationId: organizationId, jobId: jobId);
  }
}
