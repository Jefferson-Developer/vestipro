import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/size_grid_template.dart';
import '../repositories/size_grid_template_repository.dart';
import 'create_size_grid_template_use_case.dart';

@injectable
final class DuplicateSizeGridTemplateUseCase {
  const DuplicateSizeGridTemplateUseCase(
    this._repository,
    this._createSizeGridTemplate,
  );

  final SizeGridTemplateRepository _repository;
  final CreateSizeGridTemplateUseCase _createSizeGridTemplate;

  Future<AppResult<SizeGridTemplate>> call({
    required String sourceTemplateId,
    required String newTemplateId,
    required List<String> newSizeIds,
    required String organizationId,
    required String createdBy,
    String? targetName,
  }) async {
    final sourceResult = await _repository.getById(
      organizationId: organizationId,
      id: sourceTemplateId,
    );
    if (sourceResult is AppFailure<SizeGridTemplate>) return sourceResult;
    final source = (sourceResult as AppSuccess<SizeGridTemplate>).value;
    final ids = newSizeIds.map((id) => id.trim()).toList(growable: false);
    final sizes = source.orderedSizes.indexed
        .map((entry) {
          final (index, size) = entry;
          return SizeGridSize(
            id: index < ids.length ? ids[index] : '${newTemplateId}_$index',
            organizationId: organizationId,
            label: size.label,
            orderScore: index + 1,
          );
        })
        .toList(growable: false);

    return _createSizeGridTemplate(
      id: newTemplateId,
      organizationId: organizationId,
      name: targetName ?? '${source.name} cópia',
      sizes: sizes,
      createdBy: createdBy,
    );
  }
}
