import 'dart:typed_data';

import '../entities/customer_import_preview.dart';

/// Parses only a bounded preview (`kCustomerImportPreviewRowLimit` rows) of
/// an uploaded spreadsheet (TASK-167) for the column-mapping step. Never the
/// authoritative parse — that always happens server-side, in
/// `processCustomerImportJob`, against the file this same upload stored in
/// Cloud Storage.
///
/// Two implementations exist in `data/parsers`: `CsvCustomerImportFileParser`
/// (pure Dart, reads only the file's first lines) and
/// `XlsxCustomerImportFileParser` (backed by the `excel` package — cannot
/// avoid decoding the whole workbook into memory, a known limitation
/// documented on `kCustomerImportMaxFileSizeBytes`).
abstract interface class CustomerImportFileParser {
  /// Whether this parser can handle [fileName] (checked by extension).
  bool supports(String fileName);

  CustomerImportPreview parsePreview({
    required String fileName,
    required Uint8List bytes,
  });
}

/// Thrown by a [CustomerImportFileParser] when [Uint8List] bytes cannot be
/// decoded as the format its file name implies (corrupted file, wrong
/// encoding, empty spreadsheet with no header) — always caught and
/// surfaced as a user-facing message by the use case/bloc calling it, never
/// left to crash the picker flow.
final class CustomerImportParseException implements Exception {
  const CustomerImportParseException(this.message);

  final String message;

  @override
  String toString() => 'CustomerImportParseException: $message';
}
