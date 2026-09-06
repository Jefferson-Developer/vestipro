import 'dart:typed_data';

import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/customer_import_preview.dart';
import '../services/customer_import_file_parser.dart';

/// Picks the right [CustomerImportFileParser] (CSV or XLSX, by [fileName]
/// extension) and builds the bounded mapping-step preview (TASK-167).
///
/// [parsers] is DI-provided as a `List<CustomerImportFileParser>` by
/// `CustomerImportParsersModule` (`lib/app/`) — same "app-level module
/// collects every feature's concrete implementation" precedent as
/// `OfflinePackageLoadersModule`.
@injectable
final class ParseCustomerImportFileUseCase {
  ParseCustomerImportFileUseCase(this._parsers);

  final List<CustomerImportFileParser> _parsers;

  AppResult<CustomerImportPreview> call({
    required String fileName,
    required Uint8List bytes,
  }) {
    if (bytes.lengthInBytes > kCustomerImportMaxFileSizeBytes) {
      return AppFailure<CustomerImportPreview>(
        ValidationFailure(
          'Arquivo maior que o limite permitido para importação.',
          code: 'customer_import_file_too_large',
          fieldErrors: const <String, String>{
            'file':
                'O arquivo excede 15 MB. Divida a planilha em partes menores.',
          },
        ),
      );
    }

    try {
      final parser = _parsers.firstWhere(
        (candidate) => candidate.supports(fileName),
        orElse: () => throw const CustomerImportParseException(
          'Formato de arquivo não suportado. Envie um arquivo .csv ou .xlsx.',
        ),
      );
      final preview = parser.parsePreview(fileName: fileName, bytes: bytes);
      if (preview.headers.isEmpty) {
        return AppFailure<CustomerImportPreview>(
          const ValidationFailure(
            'Planilha vazia ou sem cabeçalho reconhecível.',
            code: 'customer_import_empty_file',
          ),
        );
      }
      return AppSuccess<CustomerImportPreview>(preview);
    } on CustomerImportParseException catch (exception) {
      return AppFailure<CustomerImportPreview>(
        ValidationFailure(
          exception.message,
          code: 'customer_import_parse_error',
        ),
      );
    } catch (exception) {
      return AppFailure<CustomerImportPreview>(
        UnexpectedFailure(
          'Erro inesperado ao ler o arquivo de importação.',
          code: 'customer_import_parse_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
