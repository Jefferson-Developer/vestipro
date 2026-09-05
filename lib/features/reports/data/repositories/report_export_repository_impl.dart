import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/report_branding.dart';
import '../../domain/entities/report_catalog.dart';
import '../../domain/entities/report_definition.dart';
import '../../domain/entities/report_export_result.dart';
import '../../domain/entities/report_query_result.dart';
import '../../domain/repositories/report_export_repository.dart';
import '../datasources/csv_isolate_encoder.dart';
import '../datasources/pdf_isolate_encoder.dart';
import '../datasources/report_branding_data_source.dart';
import '../datasources/report_export_remote_data_source.dart';
import '../datasources/report_file_saver_data_source.dart';
import '../datasources/xlsx_isolate_encoder.dart';

@LazySingleton(as: ReportExportRepository)
final class ReportExportRepositoryImpl implements ReportExportRepository {
  const ReportExportRepositoryImpl(
    this._isolateEncoder,
    this._xlsxIsolateEncoder,
    this._pdfIsolateEncoder,
    this._fileSaver,
    this._remote,
    this._branding,
  );

  final CsvIsolateEncoder _isolateEncoder;
  final XlsxIsolateEncoder _xlsxIsolateEncoder;
  final PdfIsolateEncoder _pdfIsolateEncoder;
  final ReportFileSaverDataSource _fileSaver;
  final ReportExportRemoteDataSource _remote;
  final ReportBrandingDataSource _branding;

  @override
  Future<List<int>> encodeCsv(
    ReportQueryResult result,
    ReportExportLocale locale,
  ) => _isolateEncoder.encode(result, locale);

  @override
  Future<List<int>> encodeXlsx(
    ReportQueryResult result,
    ReportCatalog catalog,
    ReportExportLocale locale,
  ) => _xlsxIsolateEncoder.encode(result, catalog, locale);

  @override
  Future<AppResult<String>> saveLocalFile({
    required List<int> bytes,
    required String fileName,
  }) async {
    try {
      final path = await _fileSaver.save(bytes: bytes, fileName: fileName);
      if (path == null) {
        return const AppFailure<String>(
          UnexpectedFailure(
            'Exportação cancelada.',
            code: 'report_csv_export_cancelled',
          ),
        );
      }
      return AppSuccess<String>(path);
    } catch (error) {
      return AppFailure<String>(
        UnexpectedFailure(
          'Não foi possível salvar o arquivo exportado.',
          code: 'report_csv_export_save_failed',
          cause: error,
        ),
      );
    }
  }

  @override
  Future<AppResult<ReportExportSummary>> requestCloudCsvExport({
    required ReportDefinition definition,
    required ReportExportLocale locale,
  }) async {
    try {
      final json = await _remote.exportCsv(
        definition: definition,
        locale: locale,
      );
      return AppSuccess<ReportExportSummary>(
        ReportExportSummary.fromRemoteJson(json),
      );
    } on AppException catch (error) {
      return AppFailure<ReportExportSummary>(mapAppExceptionToFailure(error));
    } catch (error) {
      return AppFailure<ReportExportSummary>(
        UnexpectedFailure(
          'Não foi possível exportar o relatório.',
          code: 'report_csv_export_remote_unexpected',
          cause: error,
        ),
      );
    }
  }

  @override
  Future<AppResult<ReportExportSummary>> requestCloudXlsxExport({
    required ReportDefinition definition,
    required ReportExportLocale locale,
  }) async {
    try {
      final json = await _remote.exportXlsx(
        definition: definition,
        locale: locale,
      );
      return AppSuccess<ReportExportSummary>(
        ReportExportSummary.fromRemoteJson(json),
      );
    } on AppException catch (error) {
      return AppFailure<ReportExportSummary>(mapAppExceptionToFailure(error));
    } catch (error) {
      return AppFailure<ReportExportSummary>(
        UnexpectedFailure(
          'Não foi possível exportar o relatório.',
          code: 'report_xlsx_export_remote_unexpected',
          cause: error,
        ),
      );
    }
  }

  @override
  Future<List<int>> encodePdf({
    required ReportDefinition definition,
    required ReportQueryResult result,
    required ReportCatalog catalog,
    required ReportBranding branding,
    required ReportExportLocale locale,
  }) => _pdfIsolateEncoder.encode(
    definition: definition,
    result: result,
    catalog: catalog,
    branding: branding,
    locale: locale,
  );

  @override
  Future<ReportBranding> loadBranding(String organizationId) =>
      _branding.resolve(organizationId);

  @override
  Future<AppResult<ReportExportSummary>> requestCloudPdfExport({
    required ReportDefinition definition,
    required ReportExportLocale locale,
  }) async {
    try {
      final json = await _remote.exportPdf(
        definition: definition,
        locale: locale,
      );
      return AppSuccess<ReportExportSummary>(
        ReportExportSummary.fromRemoteJson(json),
      );
    } on AppException catch (error) {
      return AppFailure<ReportExportSummary>(mapAppExceptionToFailure(error));
    } catch (error) {
      return AppFailure<ReportExportSummary>(
        UnexpectedFailure(
          'Não foi possível exportar o relatório.',
          code: 'report_pdf_export_remote_unexpected',
          cause: error,
        ),
      );
    }
  }
}
