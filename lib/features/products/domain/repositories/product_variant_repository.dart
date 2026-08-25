import '../../../../core/utils/utils.dart';
import '../entities/product_variant.dart';
import '../value_objects/ean.dart';
import '../value_objects/sku.dart';

abstract interface class ProductVariantRepository {
  Future<AppResult<ProductVariant>> create({required ProductVariant variant});

  Future<AppResult<ProductVariant>> update({required ProductVariant variant});

  Future<AppResult<List<ProductVariant>>> listByOrganization(
    String organizationId,
  );

  Future<AppResult<List<ProductVariant>>> listByProduct({
    required String organizationId,
    required String productId,
  });

  Future<AppResult<ProductVariant>> getById({
    required String organizationId,
    required String id,
  });

  Future<AppResult<bool>> existsBySku({
    required String organizationId,
    required Sku sku,
    String? excludingVariantId,
  });

  Future<AppResult<bool>> existsByEan({
    required String organizationId,
    required Ean ean,
    String? excludingVariantId,
  });

  Future<AppResult<bool>> isReferencedByOrder({
    required String organizationId,
    required String variantId,
  });
}
