import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/report_definition.dart';
import '../../domain/entities/report_export_result.dart';
import '../../domain/entities/report_query_result.dart';
import '../../domain/repositories/report_export_repository.dart';
import '../datasources/csv_isolate_encoder.dart';
import '../datasources/report_export_remote_data_source.dart';
import '../datasources/report_file_saver_data_source.dart';

@LazySingleton(as: ReportExportRepository)
final class ReportExportRepositoryImpl implements ReportExportRepository {
  const ReportExportRepositoryImpl(
    this._isolateEncoder,
    this._fileSaver,
    this._remote,
  );

  final CsvIsolateEncoder _isolateEncoder;
  final ReportFileSaverDataSource _fileSaver;
  final ReportExportRemoteDataSource _remote;

  @override
  Future<List<int>> encodeCsv(
    ReportQueryResult result,
    ReportExportLocale locale,
  ) => _isolateEncoder.encode(result, locale);

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
}
