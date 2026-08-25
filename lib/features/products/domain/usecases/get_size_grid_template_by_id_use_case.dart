import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/size_grid_template.dart';
import '../repositories/size_grid_template_repository.dart';

/// Looks up a single [SizeGridTemplate] by id, scoped to [organizationId] —
/// the read path `ProductDetailBloc` (TASK-078) uses to resolve the ordered
/// size columns of a product's size grid on its detail screen, mirroring
/// `GetProductByIdUseCase`'s single-entity lookup shape.
@injectable
final class GetSizeGridTemplateByIdUseCase {
  const GetSizeGridTemplateByIdUseCase(this._repository);

  final SizeGridTemplateRepository _repository;

  Future<AppResult<SizeGridTemplate>> call({
    required String organizationId,
    required String id,
  }) {
    return _repository.getById(
      organizationId: organizationId.trim(),
      id: id.trim(),
    );
  }
}
