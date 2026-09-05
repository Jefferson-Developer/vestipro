import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/reports/reports.dart';

void main() {
  const definition = ReportDefinition(
    organizationId: 'org-a',
    companyId: 'company-a',
    dimensions: <String>['seller'],
    metrics: <String>['orders'],
  );

  ReportQueryResult resultWithRows(int rowCount) => ReportQueryResult(
    columns: const <String>['seller', 'orders'],
    rows: List<Map<String, Object?>>.generate(
      rowCount,
      (index) => <String, Object?>{
        'seller': 'Vendedor $index',
        'orders': index,
      },
    ),
    generatedAt: DateTime(2026, 9, 4),
  );

  test(
    'encodes and saves the file locally when the result is within maxLocalRows',
    () async {
      final repository = _Repository();
      final useCase = ExportReportToCsv(repository);
      final result = await useCase(
        definition: definition,
        result: resultWithRows(3),
        maxLocalRows: 5000,
      );
      expect(result, isA<AppSuccess<ReportExportSummary>>());
      final summary = (result as AppSuccess<ReportExportSummary>).value;
      expect(summary.isRemote, isFalse);
      expect(summary.rowCount, 3);
      expect(repository.cloudRequests, isEmpty);
      expect(repository.savedFileNames, hasLength(1));
      expect(repository.savedFileNames.single, endsWith('.csv'));
    },
  );

  test(
    'delegates to the Cloud Function without transferring rows client-side when above maxLocalRows',
    () async {
      final repository = _Repository();
      final useCase = ExportReportToCsv(repository);
      final result = await useCase(
        definition: definition,
        result: resultWithRows(10),
        maxLocalRows: 5,
      );
      expect(result, isA<AppSuccess<ReportExportSummary>>());
      final summary = (result as AppSuccess<ReportExportSummary>).value;
      expect(summary.isRemote, isTrue);
      expect(repository.cloudRequests, hasLength(1));
      expect(repository.cloudRequests.single, same(definition));
      // The local encode/save path is never touched for the delegated flow.
      expect(repository.encodeCalls, isEmpty);
      expect(repository.savedFileNames, isEmpty);
    },
  );

  test(
    'surfaces a save failure from the repository as an AppFailure',
    () async {
      final repository = _Repository()
        ..saveLocalOverride = () =>
            const AppFailure<String>(UnexpectedFailure('boom'));
      final useCase = ExportReportToCsv(repository);
      final result = await useCase(
        definition: definition,
        result: resultWithRows(1),
        maxLocalRows: 5000,
      );
      expect(result, isA<AppFailure<ReportExportSummary>>());
    },
  );

  test(
    'surfaces an unexpected encoding error as an AppFailure instead of throwing',
    () async {
      final repository = _Repository()..throwOnEncode = true;
      final useCase = ExportReportToCsv(repository);
      final result = await useCase(
        definition: definition,
        result: resultWithRows(1),
        maxLocalRows: 5000,
      );
      expect(result, isA<AppFailure<ReportExportSummary>>());
      expect(
        (result as AppFailure<ReportExportSummary>).failure.code,
        'report_csv_export_unexpected',
      );
    },
  );

  test(
    'surfaces a remote export failure from the repository as an AppFailure',
    () async {
      final repository = _Repository()
        ..cloudOverride = () =>
            const AppFailure<ReportExportSummary>(ServerFailure('down'));
      final useCase = ExportReportToCsv(repository);
      final result = await useCase(
        definition: definition,
        result: resultWithRows(10),
        maxLocalRows: 1,
      );
      expect(result, isA<AppFailure<ReportExportSummary>>());
    },
  );
}

final class _Repository implements ReportExportRepository {
  final List<ReportDefinition> cloudRequests = <ReportDefinition>[];
  final List<String> savedFileNames = <String>[];
  final List<ReportQueryResult> encodeCalls = <ReportQueryResult>[];
  bool throwOnEncode = false;
  AppResult<String> Function()? saveLocalOverride;
  AppResult<ReportExportSummary> Function()? cloudOverride;

  @override
  Future<List<int>> encodeCsv(
    ReportQueryResult result,
    ReportExportLocale locale,
  ) async {
    encodeCalls.add(result);
    if (throwOnEncode) throw StateError('encoding failed');
    return const <int>[1, 2, 3];
  }

  @override
  Future<AppResult<String>> saveLocalFile({
    required List<int> bytes,
    required String fileName,
  }) async {
    final override = saveLocalOverride;
    if (override != null) return override();
    savedFileNames.add(fileName);
    return AppSuccess<String>('/downloads/$fileName');
  }

  @override
  Future<AppResult<ReportExportSummary>> requestCloudCsvExport({
    required ReportDefinition definition,
    required ReportExportLocale locale,
  }) async {
    cloudRequests.add(definition);
    final override = cloudOverride;
    if (override != null) return override();
    return AppSuccess<ReportExportSummary>(
      ReportExportSummary(
        fileName: 'remote.csv',
        rowCount: 10,
        location: RemoteReportExportLocation(
          downloadUrl: 'https://example.com/remote.csv',
          expiresAt: DateTime.utc(2026, 9, 5),
        ),
      ),
    );
  }
}
