import 'package:injectable/injectable.dart';

import '../features/product_import/data/parsers/csv_product_import_file_parser.dart';
import '../features/product_import/data/parsers/xlsx_product_import_file_parser.dart';
import '../features/product_import/domain/services/product_import_file_parser.dart';

/// Registers every `ProductImportFileParser` implementation
/// `ParseProductImportFileUseCase` (TASK-168) picks from by file extension —
/// mirrors `CustomerImportParsersModule` (TASK-167).
@module
abstract class ProductImportParsersModule {
  @lazySingleton
  List<ProductImportFileParser> productImportFileParsers(
    CsvProductImportFileParser csv,
    XlsxProductImportFileParser xlsx,
  ) {
    return List<ProductImportFileParser>.unmodifiable(<ProductImportFileParser>[
      csv,
      xlsx,
    ]);
  }
}
