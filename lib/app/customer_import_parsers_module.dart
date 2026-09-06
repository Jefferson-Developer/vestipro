import 'package:injectable/injectable.dart';

import '../features/customer_import/data/parsers/csv_customer_import_file_parser.dart';
import '../features/customer_import/data/parsers/xlsx_customer_import_file_parser.dart';
import '../features/customer_import/domain/services/customer_import_file_parser.dart';

/// Registers every `CustomerImportFileParser` implementation
/// `ParseCustomerImportFileUseCase` (TASK-167) picks from by file extension.
///
/// Lives in `lib/app/` — the composition root — for the same reason as
/// `OfflinePackageLoadersModule`: `core`/`domain` must never depend on every
/// feature's concrete implementation at once (see `AGENTS.md`).
@module
abstract class CustomerImportParsersModule {
  @lazySingleton
  List<CustomerImportFileParser> customerImportFileParsers(
    CsvCustomerImportFileParser csv,
    XlsxCustomerImportFileParser xlsx,
  ) {
    return List<CustomerImportFileParser>.unmodifiable(
      <CustomerImportFileParser>[csv, xlsx],
    );
  }
}
