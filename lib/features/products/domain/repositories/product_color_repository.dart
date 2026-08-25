import '../../../../core/utils/utils.dart';
import '../entities/product_color.dart';
import '../value_objects/ean.dart';

abstract interface class ProductColorRepository {
  Future<AppResult<ProductColor>> create({required ProductColor color});

  Future<AppResult<ProductColor>> update({required ProductColor color});

  Future<AppResult<List<ProductColor>>> listByOrganization(
    String organizationId,
  );

  Future<AppResult<ProductColor>> getById({
    required String organizationId,
    required String id,
  });

  Future<AppResult<bool>> eanExists({
    required String organizationId,
    required Ean ean,
    String? excludingColorId,
  });
}
