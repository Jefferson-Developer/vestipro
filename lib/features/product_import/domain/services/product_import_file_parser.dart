import 'dart:typed_data';

import '../entities/product_import_preview.dart';

/// Parses only a bounded preview (`kProductImportPreviewRowLimit` rows) of an
/// uploaded spreadsheet (TASK-168) for the column-mapping step — same
/// contract as `CustomerImportFileParser` (TASK-167). Never the
/// authoritative parse — that always happens server-side, in
/// `processProductImportJob`.
abstract interface class ProductImportFileParser {
  bool supports(String fileName);

  ProductImportPreview parsePreview({
    required String fileName,
    required Uint8List bytes,
  });
}

/// Thrown by a [ProductImportFileParser] when [Uint8List] bytes cannot be
/// decoded as the format its file name implies.
final class ProductImportParseException implements Exception {
  const ProductImportParseException(this.message);

  final String message;

  @override
  String toString() => 'ProductImportParseException: $message';
}
