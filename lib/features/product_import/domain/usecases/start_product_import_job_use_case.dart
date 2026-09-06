import 'dart:typed_data';

import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/product_import_job.dart';
import '../entities/product_import_lookup.dart';
import '../entities/product_import_mapping.dart';
import '../repositories/product_import_job_repository.dart';
import '../services/product_import_mapping_validator.dart';

@injectable
final class StartProductImportJobUseCase {
  const StartProductImportJobUseCase(this._repository);

  final ProductImportJobRepository _repository;

  Future<AppResult<ProductImportJob>> call({
    required String organizationId,
    required String companyId,
    required String fileName,
    required bool isXlsx,
    required Uint8List fileBytes,
    required ProductImportMapping mapping,
    required ProductImportLookup lookup,
    required bool createMissingCategories,
    required bool createMissingCollections,
    Map<String, Uint8List>? imageBytesByFileName,
    String? templateId,
    required String createdBy,
  }) async {
    final fieldErrors = validateProductImportMapping(mapping);
    if (fieldErrors.isNotEmpty) {
      return AppFailure<ProductImportJob>(
        ValidationFailure(
          'Mapeamento de colunas incompleto.',
          fieldErrors: fieldErrors,
          code: 'invalid_product_import_mapping',
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
      lookup: lookup,
      createMissingCategories: createMissingCategories,
      createMissingCollections: createMissingCollections,
      imageBytesByFileName: imageBytesByFileName,
      templateId: templateId,
      createdBy: createdBy,
    );
  }
}
