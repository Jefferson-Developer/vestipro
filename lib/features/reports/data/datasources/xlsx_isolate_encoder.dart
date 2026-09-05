import 'package:flutter/foundation.dart' show compute;
import 'package:injectable/injectable.dart';

import '../../domain/entities/report_catalog.dart';
import '../../domain/entities/report_export_result.dart';
import '../../domain/entities/report_query_result.dart';
import '../../domain/services/xlsx_report_encoder.dart';

/// Runs [XlsxReportEncoder] off the main isolate (TASK-147, same rationale
/// as `CsvIsolateEncoder`/TASK-146: "processar a serialização em isolate...
/// para não bloquear a UI durante a geração de arquivos grandes"). This is
/// the only piece of the XLSX export pipeline that depends on Flutter
/// (`compute`), which is exactly why it lives in `data` (behind
/// `ReportExportRepository`) instead of the domain use case.
abstract interface class XlsxIsolateEncoder {
  Future<List<int>> encode(
    ReportQueryResult result,
    ReportCatalog catalog,
    ReportExportLocale locale,
  );
}

@LazySingleton(as: XlsxIsolateEncoder)
final class FlutterXlsxIsolateEncoder implements XlsxIsolateEncoder {
  const FlutterXlsxIsolateEncoder();

  @override
  Future<List<int>> encode(
    ReportQueryResult result,
    ReportCatalog catalog,
    ReportExportLocale locale,
  ) => compute(_encodeInBackground, _XlsxEncodeJob(result, catalog, locale));
}

/// Must be a top-level (or static) function — `compute` spawns [job] into a
/// brand-new isolate that cannot close over anything from the caller.
List<int> _encodeInBackground(_XlsxEncodeJob job) => XlsxReportEncoder(
  locale: job.locale,
).encodeToBytes(job.result, job.catalog);

final class _XlsxEncodeJob {
  const _XlsxEncodeJob(this.result, this.catalog, this.locale);

  final ReportQueryResult result;
  final ReportCatalog catalog;
  final ReportExportLocale locale;
}
