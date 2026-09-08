import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/report_explanation/report_explanation.dart';
import 'package:vestipro/features/reports/reports.dart';

class _ControllableReportExplanationRepository
    implements ReportExplanationRepository {
  final _completer = Completer<AppResult<ReportExplanation>>();

  @override
  Future<AppResult<ReportExplanation>> explain({
    required ReportDefinition definition,
    String? savedReportId,
  }) => _completer.future;

  void complete(AppResult<ReportExplanation> result) =>
      _completer.complete(result);
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
        'Em setembro/2026, o total foi de R\$ 1000,00 [refs: total_revenueNet].',
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
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  group('ReportExplanationPanel', () {
    testWidgets('idle state shows the call-to-action button', (tester) async {
      final repository = _ControllableReportExplanationRepository();
      final cubit = ReportExplanationCubit(
        ExplainReportUseCase(repository, FakeAnalyticsService()),
      );

      await tester.pumpWidget(_wrap(cubit: cubit));

      expect(find.text('Explicar este relatório'), findsOneWidget);
      expect(find.byType(AppSkeleton), findsNothing);
      await cubit.close();
    });

    testWidgets('loading state shows skeleton placeholders, no button', (
      tester,
    ) async {
      final repository = _ControllableReportExplanationRepository();
      final cubit = ReportExplanationCubit(
        ExplainReportUseCase(repository, FakeAnalyticsService()),
      );
      await tester.pumpWidget(_wrap(cubit: cubit));

      unawaited(cubit.explain(definition: _buildDefinition()));
      await tester.pump();

      expect(find.text('Explicar este relatório'), findsNothing);
      expect(find.byType(AppSkeleton), findsWidgets);

      repository.complete(AppSuccess<ReportExplanation>(_buildExplanation()));
      await tester.pumpAndSettle();
      await cubit.close();
    });

    testWidgets('error state shows the message and a retry button', (
      tester,
    ) async {
      final repository = _ControllableReportExplanationRepository();
      final cubit = ReportExplanationCubit(
        ExplainReportUseCase(repository, FakeAnalyticsService()),
      );
      await tester.pumpWidget(_wrap(cubit: cubit));

      unawaited(cubit.explain(definition: _buildDefinition()));
      repository.complete(
        const AppFailure<ReportExplanation>(
          ServerFailure('Provedor indisponível.'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Provedor indisponível.'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
      await cubit.close();
    });

    testWidgets(
      'ready state shows the explanation text without raw [refs: ...] markers and expandable references',
      (tester) async {
        final repository = _ControllableReportExplanationRepository();
        final cubit = ReportExplanationCubit(
          ExplainReportUseCase(repository, FakeAnalyticsService()),
        );
        await tester.pumpWidget(_wrap(cubit: cubit));

        unawaited(cubit.explain(definition: _buildDefinition()));
        repository.complete(AppSuccess<ReportExplanation>(_buildExplanation()));
        await tester.pumpAndSettle();

        expect(
          find.text('Em setembro/2026, o total foi de R\$ 1000,00.'),
          findsOneWidget,
        );
        expect(find.textContaining('[refs:'), findsNothing);
        expect(find.text('Ver fontes dos dados (1)'), findsOneWidget);

        await tester.tap(find.text('Ver fontes dos dados (1)'));
        await tester.pumpAndSettle();

        expect(
          find.text('• Total de faturamento líquido: 1000.00 BRL'),
          findsOneWidget,
        );
        await cubit.close();
      },
    );
  });
}

Widget _wrap({required ReportExplanationCubit cubit}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: BlocProvider<ReportExplanationCubit>.value(
      value: cubit,
      child: Scaffold(
        body: SingleChildScrollView(
          child: ReportExplanationPanel(definition: _buildDefinition()),
        ),
      ),
    ),
  );
}
