import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/size_grid_template.dart';
import '../repositories/size_grid_template_repository.dart';
import '../value_objects/product_sync_status.dart';
import 'size_grid_template_use_case_helpers.dart';

@injectable
final class UpdateSizeGridTemplateUseCase {
  const UpdateSizeGridTemplateUseCase(this._repository);

  final SizeGridTemplateRepository _repository;

  Future<AppResult<SizeGridTemplate>> call({
    required String organizationId,
    required String id,
    required String name,
    required List<SizeGridSize> sizes,
    required String updatedBy,
    bool confirmPublishedProductImpact = false,
    bool confirmVariantUsage = false,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedId = id.trim();
    final trimmedUpdatedBy = updatedBy.trim();
    final validation = validateSizeGridTemplatePayload(
      organizationId: trimmedOrganizationId,
      name: name,
      sizes: sizes,
    );
    final fieldErrors = Map<String, String>.of(validation.fieldErrors);
    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedUpdatedBy.isEmpty) {
      fieldErrors['updatedBy'] = 'UpdatedBy is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<SizeGridTemplate>(
        sizeGridTemplateValidationFailure(
          fieldErrors,
          code: 'invalid_size_grid_template_update_payload',
        ),
      );
    }

    final currentResult = await _repository.getById(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
    );
    if (currentResult is AppFailure<SizeGridTemplate>) return currentResult;
    final current = (currentResult as AppSuccess<SizeGridTemplate>).value;

    final duplicateResult = await _repository.nameExists(
      organizationId: trimmedOrganizationId,
      name: name,
      excludingTemplateId: trimmedId,
    );
    if (duplicateResult is AppFailure<bool>) {
      return AppFailure<SizeGridTemplate>(duplicateResult.failure);
    }
    if ((duplicateResult as AppSuccess<bool>).value) {
      return const AppFailure<SizeGridTemplate>(
        ConflictFailure(
          'Size grid template name already exists in this organization.',
          code: 'size_grid_template_name_already_exists',
        ),
      );
    }

    if (_sizesChanged(current.orderedSizes, validation.sizes)) {
      final publishedUsage = await _repository
          .hasPublishedProductsUsingTemplate(
            organizationId: trimmedOrganizationId,
            templateId: trimmedId,
          );
      if (publishedUsage is AppFailure<bool>) {
        return AppFailure<SizeGridTemplate>(publishedUsage.failure);
      }
      if ((publishedUsage as AppSuccess<bool>).value &&
          !confirmPublishedProductImpact) {
        return const AppFailure<SizeGridTemplate>(
          ConflictFailure(
            'This size grid template is used by published products.',
            code: 'size_grid_template_product_impact_confirmation_required',
          ),
        );
      }
    }

    final removedSizeIds = current.sizes
        .map((size) => size.id)
        .where(
          (id) => validation.sizes.every((candidate) => candidate.id != id),
        )
        .toList(growable: false);
    for (final removedSizeId in removedSizeIds) {
      final usage = await _repository.sizeHasGeneratedVariants(
        organizationId: trimmedOrganizationId,
        templateId: trimmedId,
        sizeId: removedSizeId,
      );
      if (usage is AppFailure<bool>) {
        return AppFailure<SizeGridTemplate>(usage.failure);
      }
      if ((usage as AppSuccess<bool>).value && !confirmVariantUsage) {
        return AppFailure<SizeGridTemplate>(
          ConflictFailure(
            'This size is already used by generated variants.',
            code: 'size_grid_template_size_usage_confirmation_required',
            cause: removedSizeId,
          ),
        );
      }
    }

    final updated = current.copyWith(
      name: normalizeSizeGridTemplateName(name),
      sizes: validation.sizes,
      updatedAt: DateTime.now().toUtc(),
      updatedBy: trimmedUpdatedBy,
      version: current.version + 1,
      syncStatus: ProductSyncStatus.pending,
    );

    return _repository.update(template: updated);
  }

  bool _sizesChanged(List<SizeGridSize> previous, List<SizeGridSize> next) {
    if (previous.length != next.length) return true;
    for (var i = 0; i < previous.length; i++) {
      if (previous[i].id != next[i].id ||
          previous[i].label != next[i].label ||
          previous[i].orderScore != next[i].orderScore) {
        return true;
      }
    }
    return false;
  }
}
