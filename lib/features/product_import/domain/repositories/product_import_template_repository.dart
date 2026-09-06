import '../../../../core/utils/utils.dart';
import '../entities/product_import_template.dart';

/// Contract for reusable product-import column-mapping templates (TASK-168),
/// mirroring `CustomerImportTemplateRepository` (TASK-167).
abstract interface class ProductImportTemplateRepository {
  Future<AppResult<ProductImportTemplate>> save({
    required ProductImportTemplate template,
  });

  Future<AppResult<List<ProductImportTemplate>>> listByOrganization(
    String organizationId,
  );

  Future<AppResult<void>> delete({
    required String organizationId,
    required String id,
  });
}
