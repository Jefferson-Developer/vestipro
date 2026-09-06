import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/product_import_report.dart';
import '../repositories/product_import_job_repository.dart';

@injectable
final class GetProductImportJobReportUseCase {
  const GetProductImportJobReportUseCase(this._repository);

  final ProductImportJobRepository _repository;

  Future<AppResult<ProductImportReport>> call({
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
