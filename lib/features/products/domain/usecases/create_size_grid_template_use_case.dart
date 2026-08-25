import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/size_grid_template.dart';
import '../repositories/size_grid_template_repository.dart';
import '../value_objects/product_sync_status.dart';
import 'size_grid_template_use_case_helpers.dart';

@injectable
final class CreateSizeGridTemplateUseCase {
  const CreateSizeGridTemplateUseCase(this._repository);

  final SizeGridTemplateRepository _repository;

  Future<AppResult<SizeGridTemplate>> call({
    required String id,
    required String organizationId,
    required String name,
    required List<SizeGridSize> sizes,
    required String createdBy,
  }) async {
    final trimmedId = id.trim();
    final trimmedOrganizationId = organizationId.trim();
    final trimmedCreatedBy = createdBy.trim();
    final validation = validateSizeGridTemplatePayload(
      organizationId: trimmedOrganizationId,
      name: name,
      sizes: sizes,
    );
    final fieldErrors = Map<String, String>.of(validation.fieldErrors);

    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedCreatedBy.isEmpty) {
      fieldErrors['createdBy'] = 'CreatedBy is required.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<SizeGridTemplate>(
        sizeGridTemplateValidationFailure(
          fieldErrors,
          code: 'invalid_size_grid_template_create_payload',
        ),
      );
    }

    final nameExists = await _repository.nameExists(
      organizationId: trimmedOrganizationId,
      name: name,
    );
    if (nameExists is AppFailure<bool>) {
      return AppFailure<SizeGridTemplate>(nameExists.failure);
    }
    if ((nameExists as AppSuccess<bool>).value) {
      return const AppFailure<SizeGridTemplate>(
        ConflictFailure(
          'Size grid template name already exists in this organization.',
          code: 'size_grid_template_name_already_exists',
        ),
      );
    }

    final now = DateTime.now().toUtc();
    final template = SizeGridTemplate(
      id: trimmedId,
      organizationId: trimmedOrganizationId,
      name: normalizeSizeGridTemplateName(name),
      sizes: validation.sizes,
      createdAt: now,
      createdBy: trimmedCreatedBy,
      updatedAt: now,
      updatedBy: trimmedCreatedBy,
      version: 1,
      syncStatus: ProductSyncStatus.pending,
    );

    return _repository.create(template: template);
  }
}
