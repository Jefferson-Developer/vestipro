import 'dart:typed_data';

import 'package:excel/excel.dart' as xlsx;
import 'package:injectable/injectable.dart';

import '../../domain/entities/product_import_preview.dart';
import '../../domain/services/product_import_file_parser.dart';

/// XLSX parser for the mapping-step preview (TASK-168) — same known
/// limitation as `XlsxCustomerImportFileParser` (TASK-167): `excel` has no
/// streaming/partial-read API, so [kProductImportMaxFileSizeBytes] is a hard
/// client-side ceiling. The authoritative, full-file parse always happens
/// server-side (`processProductImportJob`, `exceljs`).
@lazySingleton
final class XlsxProductImportFileParser implements ProductImportFileParser {
  const XlsxProductImportFileParser();

  @override
  bool supports(String fileName) => fileName.toLowerCase().endsWith('.xlsx');

  @override
  ProductImportPreview parsePreview({
    required String fileName,
    required Uint8List bytes,
  }) {
    final xlsx.Excel workbook;
    try {
      workbook = xlsx.Excel.decodeBytes(bytes);
    } catch (exception) {
      throw ProductImportParseException(
        'Não foi possível ler o arquivo .xlsx: ${exception.toString()}',
      );
    }

    if (workbook.tables.isEmpty) {
      return ProductImportPreview(
        fileName: fileName,
        isXlsx: true,
        headers: const <String>[],
        sampleRows: const <List<String>>[],
      );
    }

    final sheet = workbook.tables.values.first;
    final rows = sheet.rows;
    if (rows.isEmpty) {
      return ProductImportPreview(
        fileName: fileName,
        isXlsx: true,
        headers: const <String>[],
        sampleRows: const <List<String>>[],
      );
    }

    final headers = _rowToStrings(rows.first);
    final sampleRows = rows
        .skip(1)
        .take(kProductImportPreviewRowLimit)
        .map(_rowToStrings)
        .toList(growable: false);

    return ProductImportPreview(
      fileName: fileName,
      isXlsx: true,
      headers: headers,
      sampleRows: sampleRows,
      totalRowsHint: sheet.maxRows > 0 ? sheet.maxRows - 1 : 0,
    );
  }

  List<String> _rowToStrings(List<xlsx.Data?> row) {
    return row
        .map((cell) => cell?.value?.toString().trim() ?? '')
        .toList(growable: false);
  }
}
