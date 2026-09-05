import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/reports/reports.dart';

void main() {
  testWidgets('renders filter chips and the empty preview accessibly', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _Repository();
    final validator = const ValidateReportDefinition();
    await tester.pumpWidget(
      MaterialApp(
        home: ReportBuilderPage(
          organizationId: 'org-a',
          companyId: 'company-a',
          userId: 'user-a',
          createBloc: () => ReportBuilderBloc(
            LoadReportCatalog(repository),
            ExecuteReportQuery(repository, validator),
            validator,
            _Drafts(),
            FakeAnalyticsService(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Vendedor'), findsOneWidget);
    expect(find.text('Pedidos'), findsOneWidget);
    expect(find.byKey(const Key('report-period-filter')), findsOneWidget);
    expect(
      find.textContaining('Selecione ao menos uma dimensão'),
      findsOneWidget,
    );
  });

  testWidgets('preview reflects exactly the server-returned columns and rows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _Repository();
    final validator = const ValidateReportDefinition();
    await tester.pumpWidget(
      MaterialApp(
        home: ReportBuilderPage(
          organizationId: 'org-a',
          companyId: 'company-a',
          userId: 'user-a',
          createBloc: () => ReportBuilderBloc(
            LoadReportCatalog(repository),
            ExecuteReportQuery(repository, validator),
            validator,
            _Drafts(),
            FakeAnalyticsService(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vendedor'));
    await tester.tap(find.text('Pedidos'));
    await tester.enterText(
      find.byKey(const Key('report-period-filter')),
      '2026-09',
    );
    await tester.ensureVisible(find.byKey(const Key('execute-report')));
    await tester.tap(find.byKey(const Key('execute-report')));
    await tester.pumpAndSettle();
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
  });
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
      id: 'orders',
      label: 'Pedidos',
      type: ReportFieldType.metric,
      valueType: ReportValueType.number,
      compatibleDimensions: <String>['seller'],
    ),
  ],
);

final class _Repository implements ReportRepository {
  @override
  Future<AppResult<ReportCatalog>> loadCatalog({
    required String organizationId,
    required String companyId,
  }) async => const AppSuccess<ReportCatalog>(_catalog);
  @override
  Future<AppResult<ReportQueryResult>> execute(
    ReportDefinition definition,
  ) async => AppSuccess<ReportQueryResult>(
    ReportQueryResult(
      columns: const <String>['seller', 'orders'],
      rows: const <Map<String, Object?>>[
        <String, Object?>{'seller': 'Ana', 'orders': 7},
      ],
      generatedAt: DateTime(2026, 9, 4),
    ),
  );
}

final class _Drafts implements ReportDraftRepository {
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
  }) async {}
}
