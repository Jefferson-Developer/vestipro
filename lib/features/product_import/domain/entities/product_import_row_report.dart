import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/product_import_row_outcome.dart';

part 'product_import_row_report.freezed.dart';

/// The outcome of one spreadsheet row, as written by
/// `processProductImportJob` into the job's report file (TASK-168). Every
/// data row of the source file gets exactly one of these.
@freezed
abstract class ProductImportRowReport with _$ProductImportRowReport {
  const factory ProductImportRowReport({
    /// 1-based position in the source file, counting only data rows.
    required int rowNumber,
    required ProductImportRowOutcome outcome,

    /// Human-readable reason, always present for
    /// [ProductImportRowOutcome.rejected], always absent for `created`.
    String? reason,
    String? sku,

    /// The created `Product.id`, only for [ProductImportRowOutcome.created].
    String? createdProductId,

    /// The created `ProductVariant.id`, only for
    /// [ProductImportRowOutcome.created].
    String? createdVariantId,

    /// Whether an uploaded image was matched to this row's SKU/reference —
    /// always `false` for a rejected row.
    @Default(false) bool imageAssociated,

    /// Raw mapped values as read from the spreadsheet (field code -> raw
    /// text), shown in the report row for context.
    @Default(<String, String>{}) Map<String, String> rawValues,
  }) = _ProductImportRowReport;
}
