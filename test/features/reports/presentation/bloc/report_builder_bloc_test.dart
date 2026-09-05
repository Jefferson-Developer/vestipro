import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/reports/reports.dart';

void main() {
  late _ReportRepository repository;
  late _DraftRepository drafts;
  late FakeAnalyticsService analytics;

  setUp(() {
    repository = _ReportRepository();
    drafts = _DraftRepository();
    analytics = FakeAnalyticsService();
  });

  ReportBuilderBloc buildBloc() {
    final validator = const ValidateReportDefinition();
    return ReportBuilderBloc(
      LoadReportCatalog(repository),
      ExecuteReportQuery(repository, validator),
      validator,
      drafts,
      analytics,
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
