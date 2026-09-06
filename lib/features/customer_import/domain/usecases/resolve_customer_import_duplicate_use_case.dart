import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../repositories/customer_import_job_repository.dart';
import '../value_objects/customer_import_duplicate_resolution.dart';

@injectable
final class ResolveCustomerImportDuplicateUseCase {
  ResolveCustomerImportDuplicateUseCase(this._repository);

  final CustomerImportJobRepository _repository;

  Future<AppResult<void>> call({
    required String organizationId,
    required String jobId,
    required int rowNumber,
    required CustomerImportDuplicateResolution resolution,
  }) {
    return _repository.resolveDuplicateRow(
      organizationId: organizationId,
      jobId: jobId,
      rowNumber: rowNumber,
      resolution: resolution,
    );
  }
}
