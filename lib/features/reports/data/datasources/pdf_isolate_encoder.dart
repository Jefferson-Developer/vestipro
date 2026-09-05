import 'package:flutter/foundation.dart' show compute;
import 'package:injectable/injectable.dart';

import '../../domain/entities/report_branding.dart';
import '../../domain/entities/report_catalog.dart';
import '../../domain/entities/report_definition.dart';
import '../../domain/entities/report_export_result.dart';
import '../../domain/entities/report_query_result.dart';
import '../../domain/services/pdf_report_encoder.dart';

/// Runs [PdfReportEncoder] off the main isolate (TASK-148, same rationale as
/// `CsvIsolateEncoder`/`XlsxIsolateEncoder`: "processar a serialização em
/// isolate... para não bloquear a UI durante a geração de arquivos
/// grandes"). This is the only piece of the PDF export pipeline that depends
/// on Flutter (`compute`), which is exactly why it lives in `data` (behind
/// `ReportExportRepository`) instead of the domain use case.
abstract interface class PdfIsolateEncoder {
  Future<List<int>> encode({
    required ReportDefinition definition,
    required ReportQueryResult result,
    required ReportCatalog catalog,
    required ReportBranding branding,
    required ReportExportLocale locale,
  });
}

@LazySingleton(as: PdfIsolateEncoder)
final class FlutterPdfIsolateEncoder implements PdfIsolateEncoder {
  const FlutterPdfIsolateEncoder();

  @override
  Future<List<int>> encode({
    required ReportDefinition definition,
    required ReportQueryResult result,
    required ReportCatalog catalog,
    required ReportBranding branding,
    required ReportExportLocale locale,
  }) => compute(
    _encodeInBackground,
    _PdfEncodeJob(definition, result, catalog, branding, locale),
  );
}

/// Must be a top-level (or static) function — `compute` spawns [job] into a
/// brand-new isolate that cannot close over anything from the caller.
Future<List<int>> _encodeInBackground(_PdfEncodeJob job) =>
    PdfReportEncoder(locale: job.locale).encodeToBytes(
      definition: job.definition,
      result: job.result,
      catalog: job.catalog,
      branding: job.branding,
    );

final class _PdfEncodeJob {
  const _PdfEncodeJob(
    this.definition,
    this.result,
    this.catalog,
    this.branding,
    this.locale,
  );

  final ReportDefinition definition;
  final ReportQueryResult result;
  final ReportCatalog catalog;
  final ReportBranding branding;
  final ReportExportLocale locale;
}
