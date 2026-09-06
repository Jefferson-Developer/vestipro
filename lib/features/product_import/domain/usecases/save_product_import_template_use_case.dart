import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/product_import_mapping.dart';
import '../entities/product_import_template.dart';
import '../repositories/product_import_template_repository.dart';

@injectable
final class SaveProductImportTemplateUseCase {
  const SaveProductImportTemplateUseCase(this._repository);

  final ProductImportTemplateRepository _repository;

  Future<AppResult<ProductImportTemplate>> call({
    required String id,
    required String organizationId,
    required String name,
    required ProductImportMapping mapping,
    DateTime? existingCreatedAt,
    String? existingCreatedBy,
    required String requestedBy,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return const AppFailure<ProductImportTemplate>(
        ValidationFailure(
          'Informe um nome para o modelo de mapeamento.',
          fieldErrors: <String, String>{
            'name': 'Informe um nome para o modelo de mapeamento.',
          },
          code: 'invalid_product_import_template_name',
        ),
      );
    }
    final now = DateTime.now().toUtc();
    final template = ProductImportTemplate(
      id: id,
      organizationId: organizationId,
      name: trimmedName,
      mapping: mapping,
      createdAt: existingCreatedAt ?? now,
      createdBy: existingCreatedBy ?? requestedBy,
      updatedAt: now,
      updatedBy: requestedBy,
    );
    return _repository.save(template: template);
  }
}
