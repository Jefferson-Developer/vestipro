import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/report_explanation/report_explanation.dart';
import 'package:vestipro/features/reports/reports.dart';

class _FakeReportExplanationRepository implements ReportExplanationRepository {
  _FakeReportExplanationRepository(this._result);

  final AppResult<ReportExplanation> _result;
  int callCount = 0;
  ReportDefinition? lastDefinition;
  String? lastSavedReportId;

  @override
  Future<AppResult<ReportExplanation>> explain({
    required ReportDefinition definition,
    String? savedReportId,
  }) async {
    callCount += 1;
    lastDefinition = definition;
    lastSavedReportId = savedReportId;
    return _result;
  }
}

ReportDefinition _buildDefinition({
  List<String> dimensions = const <String>['customer'],
  List<String> metrics = const <String>['revenueNet'],
}) => ReportDefinition(
  organizationId: 'org-1',
  companyId: 'company-1',
  dimensions: dimensions,
  metrics: metrics,
);

ReportExplanation _buildExplanation({bool fromCache = false}) {
  return ReportExplanation(
    explanationText:
        'Em setembro/2026, o total de faturamento foi de R\$ 1000,00 [refs: total_revenueNet].',
    references: const <ReportExplanationReference>[
      ReportExplanationReference(
        code: 'total_revenueNet',
        label: 'Total de faturamento líquido',
        value: '1000.00',
        unit: 'BRL',
      ),
    ],
    periodKey: '2026-09',
    generatedAt: DateTime.utc(2026, 9, 7, 10),
    expiresAt: DateTime.utc(2026, 9, 7, 11),
    fromCache: fromCache,
  );
}

void main() {
  group('ExplainReportUseCase', () {
    test(
      'requests the repository and logs reportExplanationGenerated on success',
      () async {
        final repository = _FakeReportExplanationRepository(
          AppSuccess<ReportExplanation>(_buildExplanation()),
        );
        final analytics = FakeAnalyticsService();
        final useCase = ExplainReportUseCase(repository, analytics);

        final result = await useCase(
          definition: _buildDefinition(),
          savedReportId: 'report-1',
        );

        expect(result, isA<AppSuccess<ReportExplanation>>());
        expect(repository.callCount, 1);
        expect(repository.lastSavedReportId, 'report-1');
        expect(
          analytics.loggedEvents.any(
            (event) => event.name == AnalyticsEvents.reportExplanationGenerated,
          ),
          isTrue,
        );
      },
    );

    test(
      'fails validation without calling the repository when no dimension is selected',
      () async {
        final repository = _FakeReportExplanationRepository(
          AppSuccess<ReportExplanation>(_buildExplanation()),
        );
        final analytics = FakeAnalyticsService();
        final useCase = ExplainReportUseCase(repository, analytics);

        final result = await useCase(
          definition: _buildDefinition(dimensions: const <String>[]),
        );

        expect(result, isA<AppFailure<ReportExplanation>>());
        expect(
          (result as AppFailure<ReportExplanation>).failure.code,
          'invalid_report_explanation_request',
        );
        expect(repository.callCount, 0);
        expect(analytics.loggedEvents, isEmpty);
      },
    );

    test(
      'fails validation without calling the repository when no metric is selected',
      () async {
        final repository = _FakeReportExplanationRepository(
          AppSuccess<ReportExplanation>(_buildExplanation()),
        );
        final analytics = FakeAnalyticsService();
        final useCase = ExplainReportUseCase(repository, analytics);

        final result = await useCase(
          definition: _buildDefinition(metrics: const <String>[]),
        );

        expect(result, isA<AppFailure<ReportExplanation>>());
        expect(repository.callCount, 0);
      },
    );

    test(
      'propagates a repository failure and logs reportExplanationGenerationFailed',
      () async {
        final repository = _FakeReportExplanationRepository(
          const AppFailure<ReportExplanation>(
            ConflictFailure(
              'Não foi possível gerar uma explicação confiável.',
              code: 'failed-precondition',
            ),
          ),
        );
        final analytics = FakeAnalyticsService();
        final useCase = ExplainReportUseCase(repository, analytics);

        final result = await useCase(definition: _buildDefinition());

        expect(result, isA<AppFailure<ReportExplanation>>());
        expect(
          analytics.loggedEvents.any(
            (event) =>
                event.name == AnalyticsEvents.reportExplanationGenerationFailed,
          ),
          isTrue,
        );
      },
    );
  });
}
