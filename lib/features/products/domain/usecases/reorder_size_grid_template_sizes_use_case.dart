import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/size_grid_template.dart';
import '../repositories/size_grid_template_repository.dart';
import '../value_objects/product_sync_status.dart';

@injectable
final class ReorderSizeGridTemplateSizesUseCase {
  const ReorderSizeGridTemplateSizesUseCase(this._repository);

  final SizeGridTemplateRepository _repository;

  Future<AppResult<SizeGridTemplate>> call({
    required String organizationId,
    required String templateId,
    required List<String> orderedSizeIds,
    required String updatedBy,
    bool confirmPublishedProductImpact = false,
  }) async {
    final currentResult = await _repository.getById(
      organizationId: organizationId,
      id: templateId,
    );
    if (currentResult is AppFailure<SizeGridTemplate>) return currentResult;
    final current = (currentResult as AppSuccess<SizeGridTemplate>).value;
    final ids = orderedSizeIds.map((id) => id.trim()).toList(growable: false);
    final currentIds = current.sizes.map((size) => size.id).toSet();
    if (ids.length != currentIds.length || ids.toSet().length != ids.length) {
      return const AppFailure<SizeGridTemplate>(
        ValidationFailure(
          'Invalid size reorder payload.',
          fieldErrors: <String, String>{
            'sizes': 'Reordene todos os tamanhos do template.',
          },
          code: 'invalid_size_grid_template_reorder_payload',
        ),
      );
    }
    if (ids.any((id) => !currentIds.contains(id))) {
      return const AppFailure<SizeGridTemplate>(
        ValidationFailure(
          'Invalid size reorder payload.',
          fieldErrors: <String, String>{
            'sizes': 'Reordene apenas tamanhos do template selecionado.',
          },
          code: 'invalid_size_grid_template_reorder_payload',
        ),
      );
    }

    final usage = await _repository.hasPublishedProductsUsingTemplate(
      organizationId: organizationId,
      templateId: templateId,
    );
    if (usage is AppFailure<bool>) {
      return AppFailure<SizeGridTemplate>(usage.failure);
    }
    if ((usage as AppSuccess<bool>).value && !confirmPublishedProductImpact) {
      return const AppFailure<SizeGridTemplate>(
        ConflictFailure(
          'This size grid template is used by published products.',
          code: 'size_grid_template_product_impact_confirmation_required',
        ),
      );
    }

    final byId = <String, SizeGridSize>{
      for (final size in current.sizes) size.id: size,
    };
    final reordered = ids.indexed
        .map((entry) {
          final (index, id) = entry;
          return byId[id]!.copyWith(orderScore: index + 1);
        })
        .toList(growable: false);

    final updated = current.copyWith(
      sizes: reordered,
      updatedAt: DateTime.now().toUtc(),
      updatedBy: updatedBy.trim(),
      version: current.version + 1,
      syncStatus: ProductSyncStatus.pending,
    );

    return _repository.update(template: updated);
  }
}
