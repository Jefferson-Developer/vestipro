import 'dart:convert';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';

import '../../domain/entities/product_import_preview.dart';
import '../../domain/services/product_import_file_parser.dart';

/// Pure-Dart CSV parser for the mapping-step preview (TASK-168) — same
/// bounded-read shape as `CsvCustomerImportFileParser` (TASK-167): reads
/// only the first `kProductImportPreviewRowLimit + 1` lines instead of
/// decoding the whole file. The authoritative parse of the *entire* file
/// always happens server-side (`processProductImportJob`, `exceljs`).
/// Registered as itself (not `as: ProductImportFileParser`) — see
/// `ProductImportParsersModule` (`lib/app/`) for why.
@lazySingleton
final class CsvProductImportFileParser implements ProductImportFileParser {
  const CsvProductImportFileParser();

  @override
  bool supports(String fileName) => fileName.toLowerCase().endsWith('.csv');

  @override
  ProductImportPreview parsePreview({
    required String fileName,
    required Uint8List bytes,
  }) {
    final text = _decode(bytes);
    final lines = _splitLines(
      text,
      maxLines: kProductImportPreviewRowLimit + 1,
    );
    if (lines.isEmpty) {
      return ProductImportPreview(
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

    return ProductImportPreview(
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
