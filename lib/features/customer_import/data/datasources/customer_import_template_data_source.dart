import '../dtos/customer_import_template_dto.dart';

abstract interface class CustomerImportTemplateDataSource {
  Future<List<CustomerImportTemplateDto>> listByOrganization({
    required String organizationId,
  });

  Future<void> save(CustomerImportTemplateDto dto);

  Future<void> delete({required String organizationId, required String id});
}
