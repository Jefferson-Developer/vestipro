import '../../../../core/errors/errors.dart';
import '../../domain/entities/customer_import_mapping.dart';
import '../../domain/value_objects/customer_import_field.dart';

/// Converts [CustomerImportMapping] to/from the flat
/// `{hasHeaderRow, columnByField}` shape both `CustomerImportTemplateDto`
/// and `CustomerImportJobDto` store — shared so the two DTOs never drift on
/// how a mapping is encoded.
final class CustomerImportMappingCodec {
  const CustomerImportMappingCodec._();

  static CustomerImportMapping decode({
    required bool hasHeaderRow,
    required Map<String, int> columnByField,
  }) {
    final decoded = <CustomerImportField, int>{};
    columnByField.forEach((code, column) {
      final field = CustomerImportFieldCode.fromCode(code);
      if (field == null || field == CustomerImportField.ignored) {
        throw ValidationException(
          'Invalid customer import mapping field code.',
          code: 'invalid_customer_import_mapping_field',
          cause: code,
        );
      }
      decoded[field] = column;
    });
    return CustomerImportMapping(
      hasHeaderRow: hasHeaderRow,
      columnByField: decoded,
    );
  }

  static Map<String, int> encodeColumns(CustomerImportMapping mapping) {
    return mapping.columnByField.map(
      (field, column) => MapEntry(field.code, column),
    );
  }
}
