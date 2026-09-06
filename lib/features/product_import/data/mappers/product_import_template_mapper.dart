import 'package:injectable/injectable.dart';

import '../../domain/entities/product_import_template.dart';
import '../dtos/product_import_template_dto.dart';
import 'product_import_mapping_codec.dart';

@injectable
final class ProductImportTemplateMapper {
  const ProductImportTemplateMapper();

  ProductImportTemplate toEntity(ProductImportTemplateDto dto) {
    return ProductImportTemplate(
      id: dto.id,
      organizationId: dto.organizationId,
      name: dto.name,
      mapping: ProductImportMappingCodec.decode(
        hasHeaderRow: dto.hasHeaderRow,
        columnByField: dto.columnByField,
        sizeGridTemplateId: dto.sizeGridTemplateId,
      ),
      createdAt: dto.createdAt,
      createdBy: dto.createdBy,
      updatedAt: dto.updatedAt,
      updatedBy: dto.updatedBy,
    );
  }

  ProductImportTemplateDto toDto(ProductImportTemplate template) {
    return ProductImportTemplateDto(
      id: template.id,
      organizationId: template.organizationId,
      name: template.name,
      hasHeaderRow: template.mapping.hasHeaderRow,
      columnByField: ProductImportMappingCodec.encodeColumns(template.mapping),
      sizeGridTemplateId: template.mapping.sizeGridTemplateId,
      createdAt: template.createdAt,
      createdBy: template.createdBy,
      updatedAt: template.updatedAt,
      updatedBy: template.updatedBy,
    );
  }
}
