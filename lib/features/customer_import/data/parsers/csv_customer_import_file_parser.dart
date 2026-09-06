import 'dart:convert';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';

import '../../domain/entities/customer_import_preview.dart';
import '../../domain/services/customer_import_file_parser.dart';

/// Pure-Dart CSV parser for the mapping-step preview (TASK-167). Reads only
/// the first `kCustomerImportPreviewRowLimit + 1` lines (header + sample
/// rows) instead of decoding the whole file, so a large CSV never has to be
/// fully held in memory just to build a preview — the authoritative parse
/// of the *entire* file always happens server-side
/// (`processCustomerImportJob`, using `exceljs`'s CSV reader).
///
/// Handles both `,` and `;` delimiters (auto-detected from the header line,
/// the same ambiguity `tasks.md`'s Brazilian-locale CSV export already
/// deals with — `;` is the common delimiter for a CSV opened/re-saved by a
/// pt-BR Excel), a UTF-8 BOM, quoted fields (with embedded delimiters,
/// commas or escaped `""`) and both `\n`/`\r\n` line endings.
/// Registered as itself (not `as: CustomerImportFileParser`) — see
/// `CustomerImportParsersModule` (`lib/app/`) for why: two implementations
/// of the same interface cannot both be registered `as:` it via `injectable`
/// without collision, so the module collects each concrete singleton and
/// exposes the `List<CustomerImportFileParser>`
/// `ParseCustomerImportFileUseCase` depends on instead.
@lazySingleton
final class CsvCustomerImportFileParser implements CustomerImportFileParser {
  const CsvCustomerImportFileParser();

  @override
  bool supports(String fileName) => fileName.toLowerCase().endsWith('.csv');

  @override
  CustomerImportPreview parsePreview({
    required String fileName,
    required Uint8List bytes,
  }) {
    final text = _decode(bytes);
    final lines = _splitLines(
      text,
      maxLines: kCustomerImportPreviewRowLimit + 1,
    );
    if (lines.isEmpty) {
      return CustomerImportPreview(
        fileName: fileName,
        isXlsx: false,
        headers: const <String>[],
        sampleRows: const <List<String>>[],
      );
    }

    final delimiter = _detectDelimiter(lines.first);
    final parsedRows = lines
        .map((line) => _parseLine(line, delimiter))
        .toList(growable: false);

    return CustomerImportPreview(
      fileName: fileName,
      isXlsx: false,
      headers: parsedRows.first,
      sampleRows: parsedRows.skip(1).toList(growable: false),
      totalRowsHint: _countTotalLines(text),
    );
  }

  String _decode(Uint8List bytes) {
    try {
      return utf8.decode(bytes, allowMalformed: false);
    } on FormatException {
      // Falls back to a permissive decode (latin1-compatible) instead of
      // failing outright — many legacy ERP exports use Windows-1252/Latin1,
      // not UTF-8; accentuation may render imperfectly in the preview only,
      // never silently corrupting what the Cloud Function later parses from
      // the original bytes it re-reads from Storage.
      return utf8.decode(bytes, allowMalformed: true);
    }
  }

  List<String> _splitLines(String text, {required int maxLines}) {
    final withoutBom = text.startsWith('﻿') ? text.substring(1) : text;
    final lines = <String>[];
    var start = 0;
    for (
      var index = 0;
      index < withoutBom.length && lines.length < maxLines;
      index += 1
    ) {
      final char = withoutBom[index];
      if (char == '\n') {
        var end = index;
        if (end > start && withoutBom[end - 1] == '\r') end -= 1;
        final line = withoutBom.substring(start, end);
        if (line.isNotEmpty) lines.add(line);
        start = index + 1;
      }
    }
    if (lines.length < maxLines && start < withoutBom.length) {
      final line = withoutBom.substring(start).trimRight();
      if (line.isNotEmpty) lines.add(line);
    }
    return lines;
  }

  int _countTotalLines(String text) {
    final withoutBom = text.startsWith('﻿') ? text.substring(1) : text;
    if (withoutBom.trim().isEmpty) return 0;
    final newlineCount = '\n'.allMatches(withoutBom).length;
    final endsWithNewline = withoutBom.endsWith('\n');
    // -1 for the header row; +1 more only when the file has a trailing
    // partial line with no final newline.
    return (endsWithNewline ? newlineCount : newlineCount + 1) - 1;
  }

  String _detectDelimiter(String headerLine) {
    final commaCount = ','.allMatches(headerLine).length;
    final semicolonCount = ';'.allMatches(headerLine).length;
    return semicolonCount > commaCount ? ';' : ',';
  }

  List<String> _parseLine(String line, String delimiter) {
    final fields = <String>[];
    final buffer = StringBuffer();
    var insideQuotes = false;
    for (var index = 0; index < line.length; index += 1) {
      final char = line[index];
      if (insideQuotes) {
        if (char == '"') {
          final isEscapedQuote =
              index + 1 < line.length && line[index + 1] == '"';
          if (isEscapedQuote) {
            buffer.write('"');
            index += 1;
          } else {
            insideQuotes = false;
          }
        } else {
          buffer.write(char);
        }
      } else if (char == '"') {
        insideQuotes = true;
      } else if (char == delimiter) {
        fields.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    fields.add(buffer.toString().trim());
    return fields;
  }
}
