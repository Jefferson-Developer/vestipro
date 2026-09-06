import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_import_preview.freezed.dart';

/// Bounded, client-side-only preview of an uploaded product spreadsheet
/// (TASK-168) — same contract as `CustomerImportPreview` (TASK-167): only
/// the first `kProductImportPreviewRowLimit` rows, used solely to build the
/// column-mapping step (headers, sample rows, and every distinct
/// categoria/coleção/cor name found so far so the gestor can resolve them
/// before submitting). The authoritative parse of the *entire* file always
/// happens server-side, in `processProductImportJob`.
const int kProductImportPreviewRowLimit = 20;

/// Client-side hard ceiling on the source file size (mirrors
/// `kCustomerImportMaxFileSizeBytes`, re-enforced server-side by
/// `MAX_IMPORT_FILE_SIZE_BYTES` in `product-import-shared.ts`).
const int kProductImportMaxFileSizeBytes = 15 * 1024 * 1024;

@freezed
abstract class ProductImportPreview with _$ProductImportPreview {
  const factory ProductImportPreview({
    required String fileName,
    required bool isXlsx,
    required List<String> headers,
    required List<List<String>> sampleRows,
    int? totalRowsHint,
  }) = _ProductImportPreview;
}
