import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/product_import_field.dart';

part 'product_import_mapping.freezed.dart';

/// Column mapping for a product-import spreadsheet (TASK-168): which
/// spreadsheet column (0-based index) feeds each [ProductImportField], plus
/// whether the first row is a header. Persisted verbatim inside
/// `ProductImportTemplate` for reuse, and sent to `startProductImportJob`.
///
/// [sizeGridTemplateId] is the single `SizeGridTemplate` this entire import
/// run is validated against — `tasks.md`: "grade de tamanho referenciada
/// precisa existir previamente ... nunca inferida silenciosamente", so every
/// row's [ProductImportField.sizeLabel] cell is matched against exactly this
/// grid's sizes, never guessed from an arbitrary grid.
@freezed
abstract class ProductImportMapping with _$ProductImportMapping {
  const factory ProductImportMapping({
    required bool hasHeaderRow,
    required Map<ProductImportField, int> columnByField,
    required String sizeGridTemplateId,
  }) = _ProductImportMapping;
}
