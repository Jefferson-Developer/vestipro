import 'package:freezed_annotation/freezed_annotation.dart';

import 'product_import_row_report.dart';

part 'product_import_report.freezed.dart';

/// The full report of a finished `ProductImportJob` (TASK-168) — read from
/// the JSON file `processProductImportJob` writes to
/// `organizations/{organizationId}/productImports/{jobId}/report.json`
/// (`ProductImportJob.reportStoragePath`), never from Firestore directly,
/// same rationale as `CustomerImportReport` (TASK-167).
@freezed
abstract class ProductImportReport with _$ProductImportReport {
  const factory ProductImportReport({
    required int totalRows,
    required int createdProductsCount,
    required int createdVariantsCount,
    required int imagesAssociatedCount,
    required int imagesOrphanCount,
    required int rejectedCount,
    required List<ProductImportRowReport> rows,

    /// File names from the uploaded image package that matched no SKU/
    /// reference in the spreadsheet — reported, never blocking the import
    /// of the products themselves (`tasks.md`).
    @Default(<String>[]) List<String> orphanImageFileNames,
  }) = _ProductImportReport;
}
