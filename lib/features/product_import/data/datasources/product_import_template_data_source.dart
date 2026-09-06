import '../dtos/product_import_template_dto.dart';

abstract interface class ProductImportTemplateDataSource {
  Future<List<ProductImportTemplateDto>> listByOrganization({
    required String organizationId,
  });

  Future<void> save(ProductImportTemplateDto dto);

  Future<void> delete({required String organizationId, required String id});
}
