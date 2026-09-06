import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/customer_import_job.dart';
import '../repositories/customer_import_job_repository.dart';

@injectable
final class ListCustomerImportJobsUseCase {
  ListCustomerImportJobsUseCase(this._repository);

  final CustomerImportJobRepository _repository;

  Future<AppResult<List<CustomerImportJob>>> call({
    required String organizationId,
    int limit = 20,
  }) {
    return _repository.listByOrganization(
      organizationId: organizationId,
      limit: limit,
    );
  }
}
