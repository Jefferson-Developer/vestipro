import 'package:injectable/injectable.dart';

import '../../domain/entities/customer_import_template.dart';
import '../dtos/customer_import_template_dto.dart';
import 'customer_import_mapping_codec.dart';

@injectable
final class CustomerImportTemplateMapper {
  const CustomerImportTemplateMapper();

  CustomerImportTemplate toEntity(CustomerImportTemplateDto dto) {
    return CustomerImportTemplate(
      id: dto.id,
      organizationId: dto.organizationId,
      name: dto.name,
      mapping: CustomerImportMappingCodec.decode(
        hasHeaderRow: dto.hasHeaderRow,
        columnByField: dto.columnByField,
      ),
      createdAt: dto.createdAt,
      createdBy: dto.createdBy,
      updatedAt: dto.updatedAt,
      updatedBy: dto.updatedBy,
    );
  }

  CustomerImportTemplateDto toDto(CustomerImportTemplate template) {
    return CustomerImportTemplateDto(
      id: template.id,
      organizationId: template.organizationId,
      name: template.name,
      hasHeaderRow: template.mapping.hasHeaderRow,
      columnByField: CustomerImportMappingCodec.encodeColumns(template.mapping),
      createdAt: template.createdAt,
      createdBy: template.createdBy,
      updatedAt: template.updatedAt,
      updatedBy: template.updatedBy,
    );
  }
}
