import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/product_variant.dart';
import '../repositories/product_variant_repository.dart';
import '../value_objects/product_sync_status.dart';
import '../value_objects/product_variant_status.dart';

@injectable
final class DeleteProductVariantUseCase {
  const DeleteProductVariantUseCase(this._repository);

  final ProductVariantRepository _repository;

  Future<AppResult<ProductVariant>> call({
    required String organizationId,
    required String id,
    required String deletedBy,
  }) async {
    if (deletedBy.trim().isEmpty) {
      return const AppFailure<ProductVariant>(
        ValidationFailure(
          'Invalid product variant delete payload.',
          fieldErrors: <String, String>{'deletedBy': 'DeletedBy is required.'},
          code: 'invalid_product_variant_delete_payload',
        ),
      );
    }
    final currentResult = await _repository.getById(
      organizationId: organizationId,
      id: id,
    );
    if (currentResult is AppFailure<ProductVariant>) return currentResult;
    final current = (currentResult as AppSuccess<ProductVariant>).value;

    final usageResult = await _repository.isReferencedByOrder(
      organizationId: organizationId,
      variantId: id,
    );
    if (usageResult is AppFailure<bool>) {
      return AppFailure<ProductVariant>(usageResult.failure);
    }

    final inactive = current.copyWith(
      status: ProductVariantStatus.inactive,
      updatedAt: DateTime.now().toUtc(),
      updatedBy: deletedBy.trim(),
      version: current.version + 1,
      syncStatus: ProductSyncStatus.pending,
    );
    return _repository.update(variant: inactive);
  }
}
