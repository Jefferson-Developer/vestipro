import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/product_color.dart';
import '../repositories/product_color_repository.dart';
import '../value_objects/product_color_status.dart';
import '../value_objects/product_sync_status.dart';

@injectable
final class MarkProductColorUnavailableUseCase {
  const MarkProductColorUnavailableUseCase(this._repository);

  final ProductColorRepository _repository;

  Future<AppResult<ProductColor>> call({
    required String organizationId,
    required String id,
    required String updatedBy,
  }) async {
    final currentResult = await _repository.getById(
      organizationId: organizationId.trim(),
      id: id.trim(),
    );
    if (currentResult is AppFailure<ProductColor>) return currentResult;
    final current = (currentResult as AppSuccess<ProductColor>).value;
    return _repository.update(
      color: current.copyWith(
        status: ProductColorStatus.unavailable,
        updatedAt: DateTime.now().toUtc(),
        updatedBy: updatedBy.trim(),
        version: current.version + 1,
        syncStatus: ProductSyncStatus.pending,
      ),
    );
  }
}
