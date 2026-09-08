import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/approach_suggestion/approach_suggestion.dart';

class _ControllableApproachSuggestionRepository
    implements ApproachSuggestionRepository {
  final Completer<AppResult<ApproachSuggestion>> _completer = Completer();

  @override
  Future<AppResult<ApproachSuggestion>> generate({
    required String organizationId,
    required String companyId,
    required String customerId,
  }) => _completer.future;

  void complete(AppResult<ApproachSuggestion> result) {
    _completer.complete(result);
  }
}

ApproachSuggestion _buildSuggestion({DateTime? generatedAt}) {
  return ApproachSuggestion(
    suggestedText:
        'O último pedido foi de R\$ 255,00 [refs: order_1_total_amount].',
    references: const <ApproachSuggestionReference>[
      ApproachSuggestionReference(
        code: 'order_1_total_amount',
        label: 'Valor do pedido',
        value: '255.00',
        unit: 'BRL',
      ),
    ],
    generatedAt: generatedAt ?? DateTime.utc(2026, 9, 7, 10),
    expiresAt: DateTime.utc(2026, 9, 7, 11),
    fromCache: false,
  );
}

void main() {
  group('ApproachSuggestionSheet', () {
    testWidgets('idle state shows the call-to-action button', (tester) async {
      final repository = _ControllableApproachSuggestionRepository();
      final cubit = ApproachSuggestionCubit(
        GenerateApproachSuggestionUseCase(repository, FakeAnalyticsService()),
      );

      await tester.pumpWidget(_wrap(cubit: cubit));

      expect(find.text('Sugerir abordagem'), findsOneWidget);
      expect(find.byType(AppSkeleton), findsNothing);
      await cubit.close();
    });

    testWidgets('loading state shows skeleton placeholders, no button', (
      tester,
    ) async {
      final repository = _ControllableApproachSuggestionRepository();
      final cubit = ApproachSuggestionCubit(
        GenerateApproachSuggestionUseCase(repository, FakeAnalyticsService()),
      );
      await tester.pumpWidget(_wrap(cubit: cubit));

      unawaited(
        cubit.generate(
          organizationId: 'org-1',
          companyId: 'company-1',
          customerId: 'customer-1',
        ),
      );
      await tester.pump();

      expect(find.text('Sugerir abordagem'), findsNothing);
      expect(find.byType(AppSkeleton), findsWidgets);

      repository.complete(AppSuccess<ApproachSuggestion>(_buildSuggestion()));
      await tester.pumpAndSettle();
      await cubit.close();
    });

    testWidgets('error state shows the message and a retry button', (
      tester,
    ) async {
      final repository = _ControllableApproachSuggestionRepository();
      final cubit = ApproachSuggestionCubit(
        GenerateApproachSuggestionUseCase(repository, FakeAnalyticsService()),
      );
      await tester.pumpWidget(_wrap(cubit: cubit));

      unawaited(
        cubit.generate(
          organizationId: 'org-1',
          companyId: 'company-1',
          customerId: 'customer-1',
        ),
      );
      repository.complete(
        const AppFailure<ApproachSuggestion>(
          ServerFailure('Provedor indisponível.'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Provedor indisponível.'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
      await cubit.close();
    });

    testWidgets(
      'ready state shows an editable field seeded with the suggested text, without raw [refs: ...] markers',
      (tester) async {
        final repository = _ControllableApproachSuggestionRepository();
        final cubit = ApproachSuggestionCubit(
          GenerateApproachSuggestionUseCase(repository, FakeAnalyticsService()),
        );
        await tester.pumpWidget(_wrap(cubit: cubit));

        unawaited(
          cubit.generate(
            organizationId: 'org-1',
            companyId: 'company-1',
            customerId: 'customer-1',
          ),
        );
        repository.complete(AppSuccess<ApproachSuggestion>(_buildSuggestion()));
        await tester.pumpAndSettle();

        expect(
          find.widgetWithText(
            AppTextField,
            'O último pedido foi de R\$ 255,00.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('[refs:'), findsNothing);
        expect(find.text('Ver fontes dos dados (1)'), findsOneWidget);
        expect(find.text('Usar como atividade'), findsOneWidget);

        await tester.tap(find.text('Ver fontes dos dados (1)'));
        await tester.pumpAndSettle();
        expect(find.text('• Valor do pedido: 255.00 BRL'), findsOneWidget);
        await cubit.close();
      },
    );

    testWidgets(
      'hands back the edited text (not the original) when "Usar como atividade" is tapped',
      (tester) async {
        final repository = _ControllableApproachSuggestionRepository();
        final cubit = ApproachSuggestionCubit(
          GenerateApproachSuggestionUseCase(repository, FakeAnalyticsService()),
        );
        String? handedBackText;
        await tester.pumpWidget(
          _wrap(cubit: cubit, onUseAsActivity: (text) => handedBackText = text),
        );

        unawaited(
          cubit.generate(
            organizationId: 'org-1',
            companyId: 'company-1',
            customerId: 'customer-1',
          ),
        );
        repository.complete(AppSuccess<ApproachSuggestion>(_buildSuggestion()));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(AppTextField),
          'Texto editado pelo vendedor.',
        );
        await tester.tap(find.text('Usar como atividade'));
        await tester.pumpAndSettle();

        expect(handedBackText, 'Texto editado pelo vendedor.');
        await cubit.close();
      },
    );
  });
}

Widget _wrap({
  required ApproachSuggestionCubit cubit,
  void Function(String editedText)? onUseAsActivity,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: BlocProvider<ApproachSuggestionCubit>.value(
      value: cubit,
      child: Scaffold(
        body: SingleChildScrollView(
          child: ApproachSuggestionSheet(
            organizationId: 'org-1',
            companyId: 'company-1',
            customerId: 'customer-1',
            customerName: 'Loja Exemplo',
            onUseAsActivity: onUseAsActivity ?? (_) {},
          ),
        ),
      ),
    ),
  );
}
