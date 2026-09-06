import '../entities/product_import_mapping.dart';
import '../value_objects/product_import_field.dart';

/// Validates a `ProductImportMapping` (TASK-168) before an import job may
/// start — every field in [kRequiredProductImportFields] must be mapped to a
/// column, and a `SizeGridTemplate` must be selected. Returns a field-name ->
/// message map (empty means valid), same shape
/// `validateCustomerImportMapping` (TASK-167) uses.
Map<String, String> validateProductImportMapping(ProductImportMapping mapping) {
  final fieldErrors = <String, String>{};

  for (final field in kRequiredProductImportFields) {
    if (!mapping.columnByField.containsKey(field)) {
      fieldErrors[field.code] = 'Selecione a coluna de "${field.label}".';
    }
  }

  final columns = mapping.columnByField.values.toList(growable: false);
  final duplicateColumns = columns.toSet().length != columns.length;
  if (duplicateColumns) {
    fieldErrors['columnByField'] =
        'Cada coluna da planilha só pode ser usada em um campo.';
  }

  if (mapping.sizeGridTemplateId.trim().isEmpty) {
    fieldErrors['sizeGridTemplateId'] = 'Selecione a grade de tamanho.';
  }

  return fieldErrors;
}
