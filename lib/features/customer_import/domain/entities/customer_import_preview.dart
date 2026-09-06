import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer_import_preview.freezed.dart';

/// A bounded, client-side-only preview of an uploaded spreadsheet (TASK-167)
/// — used exclusively to drive the column-mapping step
/// (`CustomerImportMappingStep`). Never the full file: [sampleRows] holds at
/// most `kCustomerImportPreviewRowLimit` data rows, so the mapping UI never
/// has to hold (nor render) a large spreadsheet in memory — the full file is
/// only ever fully parsed server-side, by `processCustomerImportJob`.
@freezed
abstract class CustomerImportPreview with _$CustomerImportPreview {
  const factory CustomerImportPreview({
    required String fileName,
    required bool isXlsx,
    required List<String> headers,
    required List<List<String>> sampleRows,

    /// Best-effort row count of the whole file (CSV: line count; XLSX:
    /// sheet's own reported row count) — `null` when it could not be
    /// determined cheaply. Only ever shown to the gestor as an estimate,
    /// never relied on for correctness: the Cloud Function counts the real
    /// total itself while processing.
    int? totalRowsHint,
  }) = _CustomerImportPreview;
}

/// At most this many data rows are parsed for the client-side preview,
/// regardless of the real file size — `AGENTS.md`'s "nunca carregar a
/// planilha inteira em memória de uma vez no cliente".
const int kCustomerImportPreviewRowLimit = 20;

/// Hard ceiling on the source file size the picker accepts (TASK-167): a
/// client-side, UX-only guard (the Cloud Function independently enforces
/// its own limit) — chosen so a mobile device never has to hold an
/// arbitrarily large file in memory before upload, and large XLSX files in
/// particular (whose preview parser must load the whole workbook, unlike
/// CSV's line-bounded read) stay within safe memory bounds.
const int kCustomerImportMaxFileSizeBytes = 15 * 1024 * 1024;
