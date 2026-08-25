import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/product_variant.dart';
import '../repositories/product_variant_repository.dart';
import '../value_objects/ean.dart';
import '../value_objects/product_sync_status.dart';
import '../value_objects/product_variant_status.dart';
import '../value_objects/sku.dart';
import '../value_objects/variant_availability_status.dart';

@injectable
final class UpdateProductVariantUseCase {
  const UpdateProductVariantUseCase(this._repository);

  final ProductVariantRepository _repository;

  Future<AppResult<ProductVariant>> call({
    required String organizationId,
    required String id,
    required String sku,
    String? ean,
    ProductVariantStatus? status,
    VariantAvailabilityStatus? manualAvailabilityStatus,
    int? manualAvailableQuantity,
    DateTime? manualFutureAvailableAt,
    bool clearManualAvailabilityStatus = false,
    bool clearManualAvailableQuantity = false,
    bool clearManualFutureAvailableAt = false,
    required String updatedBy,
  }) async {
    final fieldErrors = <String, String>{};
    Sku? parsedSku;
    try {
      parsedSku = Sku.parse(sku);
    } on ValidationException catch (exception) {
      fieldErrors.addAll(
        exception.fieldErrors.isEmpty
            ? <String, String>{'sku': exception.message}
            : exception.fieldErrors,
      );
    }

    Ean? parsedEan;
    final trimmedEan = ean?.trim();
    if (trimmedEan != null && trimmedEan.isNotEmpty) {
      try {
        parsedEan = Ean.parse(trimmedEan);
      } on ValidationException catch (exception) {
        fieldErrors.addAll(
          exception.fieldErrors.isEmpty
              ? <String, String>{'ean': exception.message}
              : exception.fieldErrors,
        );
      }
    }
    if (updatedBy.trim().isEmpty) {
      fieldErrors['updatedBy'] = 'UpdatedBy is required.';
    }
    if (manualAvailableQuantity != null && manualAvailableQuantity < 0) {
      fieldErrors['manualAvailableQuantity'] =
          'Manual available quantity must be non-negative.';
    }
    if (manualAvailabilityStatus == VariantAvailabilityStatus.futureStock &&
        manualFutureAvailableAt == null) {
      fieldErrors['manualFutureAvailableAt'] =
          'Future stock availability needs an expected date.';
    }
    if (fieldErrors.isNotEmpty || parsedSku == null) {
      return AppFailure<ProductVariant>(
        ValidationFailure(
          'Invalid product variant payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_product_variant_update_payload',
        ),
      );
    }

    final currentResult = await _repository.getById(
      organizationId: organizationId,
      id: id,
    );
    if (currentResult is AppFailure<ProductVariant>) return currentResult;
    final current = (currentResult as AppSuccess<ProductVariant>).value;

    final skuExists = await _repository.existsBySku(
      organizationId: organizationId,
      sku: parsedSku,
      excludingVariantId: id,
    );
    if (skuExists is AppFailure<bool>) {
      return AppFailure<ProductVariant>(skuExists.failure);
    }
    if ((skuExists as AppSuccess<bool>).value) {
      return const AppFailure<ProductVariant>(
        ConflictFailure(
          'Product variant SKU already exists in this organization.',
          code: 'product_variant_sku_already_exists',
        ),
      );
    }

    if (parsedEan != null) {
      final eanExists = await _repository.existsByEan(
        organizationId: organizationId,
        ean: parsedEan,
        excludingVariantId: id,
      );
      if (eanExists is AppFailure<bool>) {
        return AppFailure<ProductVariant>(eanExists.failure);
      }
      if ((eanExists as AppSuccess<bool>).value) {
        return const AppFailure<ProductVariant>(
          ConflictFailure(
            'Product variant EAN already exists in this organization.',
            code: 'product_variant_ean_already_exists',
          ),
        );
      }
    }

    final updated = current.copyWith(
      sku: parsedSku,
      ean: parsedEan,
      clearEan: trimmedEan == null || trimmedEan.isEmpty,
      manualAvailabilityStatus: manualAvailabilityStatus,
      manualAvailableQuantity: manualAvailableQuantity,
      manualFutureAvailableAt: manualFutureAvailableAt?.toUtc(),
      clearManualAvailabilityStatus: clearManualAvailabilityStatus,
      clearManualAvailableQuantity: clearManualAvailableQuantity,
      clearManualFutureAvailableAt: clearManualFutureAvailableAt,
      status: status,
      updatedAt: DateTime.now().toUtc(),
      updatedBy: updatedBy.trim(),
      version: current.version + 1,
      syncStatus: ProductSyncStatus.pending,
    );
    return _repository.update(variant: updated);
  }
}
