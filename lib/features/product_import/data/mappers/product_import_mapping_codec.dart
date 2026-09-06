import '../../../../core/errors/errors.dart';
import '../../domain/entities/product_import_mapping.dart';
import '../../domain/value_objects/product_import_field.dart';

/// Converts [ProductImportMapping] to/from the flat
/// `{hasHeaderRow, columnByField, sizeGridTemplateId}` shape both
/// `ProductImportTemplateDto` and `ProductImportJobDto` store — shared so the
/// two DTOs never drift on how a mapping is encoded, mirroring
/// `CustomerImportMappingCodec` (TASK-167).
final class ProductImportMappingCodec {
  const ProductImportMappingCodec._();

  static ProductImportMapping decode({
    required bool hasHeaderRow,
    required Map<String, int> columnByField,
    required String sizeGridTemplateId,
  }) {
    final decoded = <ProductImportField, int>{};
    columnByField.forEach((code, column) {
      final field = ProductImportFieldCode.fromCode(code);
      if (field == null || field == ProductImportField.ignored) {
        throw ValidationException(
          'Invalid product import mapping field code.',
          code: 'invalid_product_import_mapping_field',
          cause: code,
        );
      }
      decoded[field] = column;
    });
    return ProductImportMapping(
      hasHeaderRow: hasHeaderRow,
      columnByField: decoded,
      sizeGridTemplateId: sizeGridTemplateId,
    );
  }

  static Map<String, int> encodeColumns(ProductImportMapping mapping) {
    return mapping.columnByField.map(
      (field, column) => MapEntry(field.code, column),
    );
  }
}
