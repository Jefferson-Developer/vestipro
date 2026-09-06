import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/customer_import_report.dart';
import '../repositories/customer_import_job_repository.dart';

@injectable
final class GetCustomerImportJobReportUseCase {
  GetCustomerImportJobReportUseCase(this._repository);

  final CustomerImportJobRepository _repository;

  Future<AppResult<CustomerImportReport>> call({
    required String organizationId,
    required String jobId,
    required String reportStoragePath,
  }) {
    return _repository.getReport(
      organizationId: organizationId,
      jobId: jobId,
      reportStoragePath: reportStoragePath,
    );
  }
}
