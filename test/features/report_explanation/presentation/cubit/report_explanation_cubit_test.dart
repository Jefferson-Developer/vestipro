import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/report_explanation/report_explanation.dart';
import 'package:vestipro/features/reports/reports.dart';

class _FakeReportExplanationRepository implements ReportExplanationRepository {
  _FakeReportExplanationRepository(this._result);

  final AppResult<ReportExplanation> Function() _result;

  @override
  Future<AppResult<ReportExplanation>> explain({
    required ReportDefinition definition,
    String? savedReportId,
  }) async => _result();
}

ReportDefinition _buildDefinition() => const ReportDefinition(
  organizationId: 'org-1',
  companyId: 'company-1',
  dimensions: <String>['customer'],
  metrics: <String>['revenueNet'],
);

ReportExplanation _buildExplanation() {
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
    fromCache: false,
  );
}

void main() {
  group('ReportExplanationCubit', () {
    test('starts idle', () {
      final useCase = ExplainReportUseCase(
        _FakeReportExplanationRepository(
          () => AppSuccess<ReportExplanation>(_buildExplanation()),
        ),
        FakeAnalyticsService(),
      );
      final cubit = ReportExplanationCubit(useCase);
      expect(cubit.state.status, ReportExplanationStatus.idle);
      unawaited(cubit.close());
    });

    blocTest<ReportExplanationCubit, ReportExplanationState>(
      'emits [loading, ready] on a successful explain()',
      build: () => ReportExplanationCubit(
        ExplainReportUseCase(
          _FakeReportExplanationRepository(
            () => AppSuccess<ReportExplanation>(_buildExplanation()),
          ),
          FakeAnalyticsService(),
        ),
      ),
      act: (cubit) => cubit.explain(definition: _buildDefinition()),
      expect: () => <dynamic>[
        isA<ReportExplanationState>().having(
          (state) => state.status,
          'status',
          ReportExplanationStatus.loading,
        ),
        isA<ReportExplanationState>()
            .having(
              (state) => state.status,
              'status',
              ReportExplanationStatus.ready,
            )
            .having(
              (state) => state.explanation?.explanationText,
              'explanationText',
              isNotNull,
            ),
      ],
    );

    blocTest<ReportExplanationCubit, ReportExplanationState>(
      'emits [loading, error] when the repository fails',
      build: () => ReportExplanationCubit(
        ExplainReportUseCase(
          _FakeReportExplanationRepository(
            () => const AppFailure<ReportExplanation>(
              ServerFailure('Provedor indisponível.', code: 'unavailable'),
            ),
          ),
          FakeAnalyticsService(),
        ),
      ),
      act: (cubit) => cubit.explain(definition: _buildDefinition()),
      expect: () => <dynamic>[
        isA<ReportExplanationState>().having(
          (state) => state.status,
          'status',
          ReportExplanationStatus.loading,
        ),
        isA<ReportExplanationState>()
            .having(
              (state) => state.status,
              'status',
              ReportExplanationStatus.error,
            )
            .having(
              (state) => state.failure?.code,
              'failure.code',
              'unavailable',
            ),
      ],
    );

    test(
      'reset() returns to idle while keeping the last explanation',
      () async {
        final useCase = ExplainReportUseCase(
          _FakeReportExplanationRepository(
            () => AppSuccess<ReportExplanation>(_buildExplanation()),
          ),
          FakeAnalyticsService(),
        );
        final cubit = ReportExplanationCubit(useCase);
        await cubit.explain(definition: _buildDefinition());
        expect(cubit.state.status, ReportExplanationStatus.ready);

        cubit.reset();

        expect(cubit.state.status, ReportExplanationStatus.idle);
        expect(cubit.state.explanation, isNotNull);
        await cubit.close();
      },
    );
  });
}
