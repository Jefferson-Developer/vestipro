import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/customer_import_mapping.dart';
import '../entities/customer_import_template.dart';
import '../repositories/customer_import_template_repository.dart';

@injectable
final class SaveCustomerImportTemplateUseCase {
  SaveCustomerImportTemplateUseCase(this._repository);

  final CustomerImportTemplateRepository _repository;

  Future<AppResult<CustomerImportTemplate>> call({
    required String id,
    required String organizationId,
    required String name,
    required CustomerImportMapping mapping,
    DateTime? existingCreatedAt,
    String? existingCreatedBy,
    required String requestedBy,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return AppFailure<CustomerImportTemplate>(
        const ValidationFailure(
          'Nome do template é obrigatório.',
          code: 'invalid_customer_import_template_name',
          fieldErrors: <String, String>{
            'name': 'Informe um nome para o template.',
          },
        ),
      );
    }

    final now = DateTime.now().toUtc();
    final template = CustomerImportTemplate(
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
