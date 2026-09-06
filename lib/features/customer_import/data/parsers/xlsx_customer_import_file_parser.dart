import 'dart:typed_data';

import 'package:excel/excel.dart' as xlsx;
import 'package:injectable/injectable.dart';

import '../../domain/entities/customer_import_preview.dart';
import '../../domain/services/customer_import_file_parser.dart';

/// XLSX parser for the mapping-step preview (TASK-167), backed by the
/// pure-Dart `excel` package (already a dependency, TASK-147's report
/// export).
///
/// Known limitation, documented rather than hidden: `excel` has no
/// streaming/partial-read API — decoding even just the header requires
/// loading the whole workbook into memory first. This is why
/// [kCustomerImportMaxFileSizeBytes] exists as a hard client-side ceiling
/// and why the mapping-step preview itself still only *renders*
/// `kCustomerImportPreviewRowLimit` rows after that decode. The
/// authoritative, full-file parse for actually creating customers always
/// happens server-side (`processCustomerImportJob`, `exceljs`), independent
/// of this class.
/// Registered as itself — see `CsvCustomerImportFileParser`'s docs and
/// `CustomerImportParsersModule` (`lib/app/`) for why.
@lazySingleton
final class XlsxCustomerImportFileParser implements CustomerImportFileParser {
  const XlsxCustomerImportFileParser();

  @override
  bool supports(String fileName) => fileName.toLowerCase().endsWith('.xlsx');

  @override
  CustomerImportPreview parsePreview({
    required String fileName,
    required Uint8List bytes,
  }) {
    final xlsx.Excel workbook;
    try {
      workbook = xlsx.Excel.decodeBytes(bytes);
    } catch (exception) {
      throw CustomerImportParseException(
        'Não foi possível ler o arquivo .xlsx: ${exception.toString()}',
      );
    }

    if (workbook.tables.isEmpty) {
      return CustomerImportPreview(
        fileName: fileName,
        isXlsx: true,
        headers: const <String>[],
        sampleRows: const <List<String>>[],
      );
    }

    final sheet = workbook.tables.values.first;
    final rows = sheet.rows;
    if (rows.isEmpty) {
      return CustomerImportPreview(
        fileName: fileName,
        isXlsx: true,
        headers: const <String>[],
        sampleRows: const <List<String>>[],
      );
    }

    final headers = _rowToStrings(rows.first);
    final sampleRows = rows
        .skip(1)
        .take(kCustomerImportPreviewRowLimit)
        .map(_rowToStrings)
        .toList(growable: false);

    return CustomerImportPreview(
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
