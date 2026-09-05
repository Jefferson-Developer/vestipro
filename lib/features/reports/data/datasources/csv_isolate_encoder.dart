import 'package:flutter/foundation.dart' show compute;
import 'package:injectable/injectable.dart';

import '../../domain/entities/report_export_result.dart';
import '../../domain/entities/report_query_result.dart';
import '../../domain/services/csv_report_encoder.dart';

/// Runs [CsvReportEncoder] off the main isolate (TASK-146: "processar a
/// serialização em isolate... para não bloquear a UI durante a geração de
/// arquivos grandes"). This is the only piece of the export pipeline that
/// depends on Flutter (`compute`), which is exactly why it lives in `data`
/// (behind `ReportExportRepository`) instead of the domain use case — the
/// domain layer decides *whether* to encode locally, this datasource decides
/// *how* the encoding itself is scheduled.
abstract interface class CsvIsolateEncoder {
  Future<List<int>> encode(ReportQueryResult result, ReportExportLocale locale);
}

@LazySingleton(as: CsvIsolateEncoder)
final class FlutterCsvIsolateEncoder implements CsvIsolateEncoder {
  const FlutterCsvIsolateEncoder();

  @override
  Future<List<int>> encode(
    ReportQueryResult result,
    ReportExportLocale locale,
  ) => compute(_encodeInBackground, _CsvEncodeJob(result, locale));
}

/// Must be a top-level (or static) function — `compute` spawns [job] into a
/// brand-new isolate that cannot close over anything from the caller.
List<int> _encodeInBackground(_CsvEncodeJob job) =>
    CsvReportEncoder(locale: job.locale).encodeToBytes(job.result);

final class _CsvEncodeJob {
  const _CsvEncodeJob(this.result, this.locale);

  final ReportQueryResult result;
  final ReportExportLocale locale;
}
