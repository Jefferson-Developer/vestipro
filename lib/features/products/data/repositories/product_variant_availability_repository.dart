import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/product_variant.dart';
import '../../domain/entities/variant_availability.dart';
import '../../domain/repositories/product_variant_repository.dart';
import '../../domain/repositories/variant_availability_repository.dart';

/// Initial TASK-074 availability source.
///
/// This reads manual availability metadata from [ProductVariant]. TASK-090
/// can replace this repository with an inventory-balance implementation
/// while keeping [VariantAvailabilityRepository] and the UI contracts stable.
@LazySingleton(as: VariantAvailabilityRepository)
final class ProductVariantAvailabilityRepository
    implements VariantAvailabilityRepository {
  const ProductVariantAvailabilityRepository(this._variants);

  final ProductVariantRepository _variants;

  @override
  Future<AppResult<List<VariantAvailability>>> listByVariantIds({
    required String organizationId,
    required Iterable<String> variantIds,
  }) async {
    try {
      final availabilities = <VariantAvailability>[];
      for (final variantId in variantIds) {
        final result = await _variants.getById(
          organizationId: organizationId,
          id: variantId,
        );
        if (result is AppFailure<ProductVariant>) {
          return AppFailure<List<VariantAvailability>>(result.failure);
        }
        availabilities.add(
          VariantAvailability.fromVariant(
            (result as AppSuccess<ProductVariant>).value,
          ),
        );
      }
      return AppSuccess<List<VariantAvailability>>(availabilities);
    } on AppException catch (exception) {
      return AppFailure<List<VariantAvailability>>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<List<VariantAvailability>>(
        UnexpectedFailure(
          'Unexpected error loading variant availability.',
          code: 'variant_availability_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<VariantAvailability>>> listByProductIds({
    required String organizationId,
    required Iterable<String> productIds,
  }) async {
    try {
      final availabilities = <VariantAvailability>[];
      for (final productId in productIds) {
        final result = await _variants.listByProduct(
          organizationId: organizationId,
          productId: productId,
        );
        if (result is AppFailure<List<ProductVariant>>) {
          return AppFailure<List<VariantAvailability>>(result.failure);
        }
        availabilities.addAll(
          (result as AppSuccess<List<ProductVariant>>).value.map(
            VariantAvailability.fromVariant,
          ),
        );
      }
      return AppSuccess<List<VariantAvailability>>(availabilities);
    } on AppException catch (exception) {
      return AppFailure<List<VariantAvailability>>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<List<VariantAvailability>>(
        UnexpectedFailure(
          'Unexpected error loading product availability.',
          code: 'variant_availability_product_list_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
