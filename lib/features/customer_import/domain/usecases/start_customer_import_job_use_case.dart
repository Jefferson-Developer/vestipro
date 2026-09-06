import 'dart:typed_data';

import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/customer_import_job.dart';
import '../entities/customer_import_mapping.dart';
import '../repositories/customer_import_job_repository.dart';
import '../services/customer_import_mapping_validator.dart';

@injectable
final class StartCustomerImportJobUseCase {
  StartCustomerImportJobUseCase(this._repository);

  final CustomerImportJobRepository _repository;

  Future<AppResult<CustomerImportJob>> call({
    required String organizationId,
    required String companyId,
    required String fileName,
    required bool isXlsx,
    required Uint8List fileBytes,
    required CustomerImportMapping mapping,
    String? templateId,
    required String createdBy,
  }) async {
    final fieldErrors = validateCustomerImportMapping(mapping);
    if (fieldErrors.isNotEmpty) {
      return AppFailure<CustomerImportJob>(
        ValidationFailure(
          'Mapeamento de colunas incompleto.',
          fieldErrors: fieldErrors,
          code: 'invalid_customer_import_mapping',
        ),
      );
    }

    return _repository.startJob(
      organizationId: organizationId,
      companyId: companyId,
      fileName: fileName,
      isXlsx: isXlsx,
      fileBytes: fileBytes,
      mapping: mapping,
      templateId: templateId,
      createdBy: createdBy,
    );
  }
}
