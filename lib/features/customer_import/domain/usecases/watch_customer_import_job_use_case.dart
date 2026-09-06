import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/customer_import_job.dart';
import '../repositories/customer_import_job_repository.dart';

@injectable
final class WatchCustomerImportJobUseCase {
  WatchCustomerImportJobUseCase(this._repository);

  final CustomerImportJobRepository _repository;

  Stream<AppResult<CustomerImportJob>> call({
    required String organizationId,
    required String jobId,
  }) {
    return _repository.watchJob(organizationId: organizationId, jobId: jobId);
  }
}
