import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/feature_flags/feature_flags.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/reports/reports.dart';

void main() {
  late _ReportRepository repository;
  late _DraftRepository drafts;
  late FakeAnalyticsService analytics;
  late _ReportExportRepository exportRepository;
  late FakeFeatureFlagService featureFlags;

  setUp(() {
    repository = _ReportRepository();
    drafts = _DraftRepository();
    analytics = FakeAnalyticsService();
    exportRepository = _ReportExportRepository();
    featureFlags = FakeFeatureFlagService();
  });

  ReportBuilderBloc buildBloc() {
    final validator = const ValidateReportDefinition();
    return ReportBuilderBloc(
      LoadReportCatalog(repository),
      ExecuteReportQuery(repository, validator),
      validator,
      drafts,
      analytics,
      ExportReportToCsv(exportRepository),
      featureFlags,
    );
  }

  blocTest<ReportBuilderBloc, ReportBuilderState>(
    'valid selection executes the server query with unchanged tenant scope',
    build: buildBloc,
    act: (bloc) async {
      bloc.add(
        const ReportBuilderStarted(
          organizationId: 'org-a',
          companyId: 'company-a',
          userId: 'user-a',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ReportDimensionToggled('seller'));
      bloc.add(const ReportMetricToggled('orders'));
      bloc.add(
        const ReportFilterChanged(
          ReportFilter(
            fieldId: 'period',
            operatorId: 'equals',
            value: '2026-09',
          ),
        ),
      );
      bloc.add(const ReportExecutionRequested());
    },
    wait: const Duration(milliseconds: 20),
    verify: (_) {
      expect(repository.executed, hasLength(1));
      expect(repository.executed.single.organizationId, 'org-a');
      expect(repository.executed.single.companyId, 'company-a');
      expect(
        analytics.loggedEvents.map((event) => event.name),
        containsAll(<String>[
          AnalyticsEvents.reportBuilt,
          AnalyticsEvents.reportQueryExecuted,
        ]),
      );
    },
  );

  blocTest<ReportBuilderBloc, ReportBuilderState>(
    'incompatible selection never reaches backend and surfaces an explanation',
    build: buildBloc,
    act: (bloc) async {
      bloc.add(
        const ReportBuilderStarted(
          organizationId: 'org-a',
          companyId: 'company-a',
          userId: 'user-a',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ReportDimensionToggled('product'));
      bloc.add(const ReportMetricToggled('orders'));
      bloc.add(const ReportExecutionRequested());
    },
    wait: const Duration(milliseconds: 20),
    verify: (bloc) {
      expect(repository.executed, isEmpty);
      expect(bloc.state.validationMessage, isNotNull);
    },
  );

  blocTest<ReportBuilderBloc, ReportBuilderState>(
    'changing dimension removes an already selected incompatible metric and persists draft',
    build: buildBloc,
    act: (bloc) async {
      bloc.add(
        const ReportBuilderStarted(
          organizationId: 'org-a',
          companyId: 'company-a',
          userId: 'user-a',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ReportDimensionToggled('seller'));
      bloc.add(const ReportMetricToggled('orders'));
      bloc.add(const ReportDimensionToggled('seller'));
      bloc.add(const ReportDimensionToggled('product'));
    },
    wait: const Duration(milliseconds: 20),
    verify: (bloc) {
      expect(bloc.state.definition!.metrics, isEmpty);
      expect(drafts.saved, isNotEmpty);
    },
  );

  blocTest<ReportBuilderBloc, ReportBuilderState>(
    'export requested below the configured threshold saves the CSV locally and logs analytics (TASK-146)',
    build: buildBloc,
    act: (bloc) async {
      bloc.add(
        const ReportBuilderStarted(
          organizationId: 'org-a',
          companyId: 'company-a',
          userId: 'user-a',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ReportDimensionToggled('seller'));
      bloc.add(const ReportMetricToggled('orders'));
      bloc.add(
        const ReportFilterChanged(
          ReportFilter(
            fieldId: 'period',
            operatorId: 'equals',
            value: '2026-09',
          ),
        ),
      );
      bloc.add(const ReportExecutionRequested());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const ReportExportRequested());
    },
    wait: const Duration(milliseconds: 20),
    verify: (bloc) {
      expect(exportRepository.cloudRequests, isEmpty);
      expect(exportRepository.savedFileNames, hasLength(1));
      expect(bloc.state.exportStatus, ReportExportStatus.success);
      expect(bloc.state.exportSummary?.isRemote, isFalse);
      expect(bloc.state.exportSummary?.rowCount, 1);
      final exportedEvent = analytics.loggedEvents.firstWhere(
        (event) => event.name == AnalyticsEvents.reportExported,
      );
      expect(exportedEvent.parameters?['formato'], 'csv');
      expect(exportedEvent.parameters?['row_count'], 1);
      expect(exportedEvent.parameters?['delegated_to_cloud'], false);
    },
  );

  blocTest<ReportBuilderBloc, ReportBuilderState>(
    'export above the configured threshold delegates to the Cloud Function with unchanged tenant scope (TASK-146)',
    build: buildBloc,
    setUp: () => featureFlags.overrideFlag(
      FeatureFlagRegistry.configReportExportMaxLocalRows,
      0,
    ),
    act: (bloc) async {
      bloc.add(
        const ReportBuilderStarted(
          organizationId: 'org-a',
          companyId: 'company-a',
          userId: 'user-a',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ReportDimensionToggled('seller'));
      bloc.add(const ReportMetricToggled('orders'));
      bloc.add(
        const ReportFilterChanged(
          ReportFilter(
            fieldId: 'period',
            operatorId: 'equals',
            value: '2026-09',
          ),
        ),
      );
      bloc.add(const ReportExecutionRequested());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const ReportExportRequested());
    },
    wait: const Duration(milliseconds: 20),
    verify: (bloc) {
      expect(exportRepository.savedFileNames, isEmpty);
      expect(exportRepository.cloudRequests, hasLength(1));
      expect(exportRepository.cloudRequests.single.organizationId, 'org-a');
      expect(exportRepository.cloudRequests.single.companyId, 'company-a');
      expect(bloc.state.exportStatus, ReportExportStatus.success);
      expect(bloc.state.exportSummary?.isRemote, isTrue);
    },
  );

  blocTest<ReportBuilderBloc, ReportBuilderState>(
    'export failure surfaces the failure without discarding the still-valid preview (TASK-146)',
    build: buildBloc,
    setUp: () =>
        exportRepository.saveLocalOverride = () =>
            const AppFailure<String>(UnexpectedFailure('boom')),
    act: (bloc) async {
      bloc.add(
        const ReportBuilderStarted(
          organizationId: 'org-a',
          companyId: 'company-a',
          userId: 'user-a',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ReportDimensionToggled('seller'));
      bloc.add(const ReportMetricToggled('orders'));
      bloc.add(
        const ReportFilterChanged(
          ReportFilter(
            fieldId: 'period',
            operatorId: 'equals',
            value: '2026-09',
          ),
        ),
      );
      bloc.add(const ReportExecutionRequested());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const ReportExportRequested());
    },
    wait: const Duration(milliseconds: 20),
    verify: (bloc) {
      expect(bloc.state.exportStatus, ReportExportStatus.failure);
      expect(bloc.state.exportFailure, isNotNull);
      expect(bloc.state.preview, isNotNull);
    },
  );
}

const _catalog = ReportCatalog(
  fields: <ReportFieldDefinition>[
    ReportFieldDefinition(
      id: 'seller',
      label: 'Vendedor',
      type: ReportFieldType.dimension,
      valueType: ReportValueType.text,
    ),
    ReportFieldDefinition(
      id: 'product',
      label: 'Produto',
      type: ReportFieldType.dimension,
      valueType: ReportValueType.text,
    ),
    ReportFieldDefinition(
      id: 'orders',
      label: 'Pedidos',
      type: ReportFieldType.metric,
      valueType: ReportValueType.number,
      compatibleDimensions: <String>['seller'],
    ),
  ],
);

final class _ReportRepository implements ReportRepository {
  final List<ReportDefinition> executed = <ReportDefinition>[];
  @override
  Future<AppResult<ReportCatalog>> loadCatalog({
    required String organizationId,
    required String companyId,
  }) async => const AppSuccess<ReportCatalog>(_catalog);
  @override
  Future<AppResult<ReportQueryResult>> execute(
    ReportDefinition definition,
  ) async {
    executed.add(definition);
    return AppSuccess<ReportQueryResult>(
      ReportQueryResult(
        columns: const <String>['seller', 'orders'],
        rows: const <Map<String, Object?>>[
          <String, Object?>{'seller': 'Ana', 'orders': 4},
        ],
        generatedAt: DateTime(2026, 9, 4),
      ),
    );
  }
}

final class _DraftRepository implements ReportDraftRepository {
  final List<ReportDefinition> saved = <ReportDefinition>[];
  @override
  Future<ReportDefinition?> load({
    required String userId,
    required String organizationId,
    required String companyId,
  }) async => null;
  @override
  Future<void> save({
    required String userId,
    required ReportDefinition definition,
  }) async {
    saved.add(definition);
  }
}

final class _ReportExportRepository implements ReportExportRepository {
  final List<ReportDefinition> cloudRequests = <ReportDefinition>[];
  final List<String> savedFileNames = <String>[];
  AppResult<String> Function()? saveLocalOverride;
  AppResult<ReportExportSummary> Function()? cloudOverride;

  @override
  Future<List<int>> encodeCsv(
    ReportQueryResult result,
    ReportExportLocale locale,
  ) async => const <int>[1, 2, 3];

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
        fileName: 'remote_report.csv',
        rowCount: 999,
        location: RemoteReportExportLocation(
          downloadUrl: 'https://example.com/remote_report.csv',
          expiresAt: DateTime.utc(2026, 9, 5),
        ),
      ),
    );
  }
}
