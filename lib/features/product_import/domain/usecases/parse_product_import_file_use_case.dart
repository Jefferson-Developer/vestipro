import 'dart:typed_data';

import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/product_import_preview.dart';
import '../services/product_import_file_parser.dart';

/// Parses an uploaded file's bounded preview (TASK-168), picking the first
/// [ProductImportFileParser] that `supports` the file name — same shape as
/// `ParseCustomerImportFileUseCase` (TASK-167).
@injectable
final class ParseProductImportFileUseCase {
  const ParseProductImportFileUseCase(this._parsers);

  final List<ProductImportFileParser> _parsers;

  AppResult<ProductImportPreview> call({
    required String fileName,
    required Uint8List bytes,
  }) {
    try {
      if (bytes.length > kProductImportMaxFileSizeBytes) {
        return AppFailure<ProductImportPreview>(
          const ValidationFailure(
            'Arquivo maior que o limite permitido (15 MB).',
            code: 'product_import_file_too_large',
          ),
        );
      }
      final parser = _parsers
          .where((candidate) => candidate.supports(fileName))
          .firstOrNull;
      if (parser == null) {
        return AppFailure<ProductImportPreview>(
          const ValidationFailure(
            'Formato de arquivo não suportado. Use .csv ou .xlsx.',
            code: 'product_import_unsupported_file_format',
          ),
        );
      }
      final preview = parser.parsePreview(fileName: fileName, bytes: bytes);
      return AppSuccess<ProductImportPreview>(preview);
    } on ProductImportParseException catch (exception) {
      return AppFailure<ProductImportPreview>(
        ValidationFailure(
          exception.message,
          code: 'product_import_parse_failed',
        ),
      );
    } catch (exception) {
      return AppFailure<ProductImportPreview>(
        UnexpectedFailure(
          'Unexpected error parsing product import file.',
          code: 'product_import_parse_unexpected',
          cause: exception,
        ),
      );
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
