import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/customer_import_field.dart';

part 'customer_import_mapping.freezed.dart';

/// How a spreadsheet's columns translate into `Customer` fields (TASK-167).
///
/// [columnByField] only ever contains fields the gestor actually mapped —
/// [CustomerImportField.ignored] is never a key, it is simply the absence of
/// one. Column indexes are 0-based positions inside each parsed row
/// (`CustomerImportPreview.headers`/`sampleRows`), stable regardless of
/// whether [hasHeaderRow] is true (a header row, when present, is only ever
/// used for display/auto-suggestion, never counted as a data row).
@freezed
abstract class CustomerImportMapping with _$CustomerImportMapping {
  const CustomerImportMapping._();

  const factory CustomerImportMapping({
    required bool hasHeaderRow,
    required Map<CustomerImportField, int> columnByField,
  }) = _CustomerImportMapping;

  int? columnFor(CustomerImportField field) => columnByField[field];

  bool get mapsDocument =>
      columnByField.containsKey(CustomerImportField.document);

  bool get mapsAnyNameField =>
      columnByField.containsKey(CustomerImportField.legalName) ||
      columnByField.containsKey(CustomerImportField.tradeName) ||
      columnByField.containsKey(CustomerImportField.fullName);
}
