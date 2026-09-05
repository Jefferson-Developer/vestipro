import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/privacy/privacy.dart';

void main() {
  testWidgets(
    'documentos ficam acessíveis fora do bloqueio sem pedir novo aceite',
    (tester) async {
      final repository = _FakePolicyRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: PolicyDocumentsPage(
            requireAcceptance: false,
            createCubit: () => _cubit(repository, ''),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Privacidade e termos'), findsOneWidget);
      expect(find.text('Política de Privacidade'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('policy-acceptance-checkbox')),
        findsNothing,
      );
    },
  );

  testWidgets('fluxo bloqueante exige checkbox explícito antes de aceitar', (
    tester,
  ) async {
    final repository = _FakePolicyRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PolicyDocumentsPage(
          requireAcceptance: true,
          createCubit: () => _cubit(repository, 'user-a'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final button = tester.widget<AppButton>(
      find.byKey(const ValueKey('policy-acceptance-button')),
    );
    expect(button.onPressed, isNull);
    await tester.tap(find.byKey(const ValueKey('policy-acceptance-checkbox')));
    await tester.pump();
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const ValueKey('policy-acceptance-button')),
          )
          .onPressed,
      isNotNull,
    );
  });
}

PolicyAcceptanceCubit _cubit(PolicyRepository repository, String userId) =>
    PolicyAcceptanceCubit(
      evaluate: EvaluatePolicyAcceptanceUseCase(repository),
      acceptCurrent: AcceptCurrentPoliciesUseCase(repository),
      getDocuments: GetCurrentPolicyDocumentsUseCase(repository),
      userId: userId,
      device: 'test',
    );

final class _FakePolicyRepository implements PolicyRepository {
  final documents = <PolicyDocument>[
    PolicyDocument(
      type: PolicyDocumentType.privacyPolicy,
      version: '1',
      content: 'Conteúdo da privacidade.',
      publishedAt: DateTime.utc(2026),
    ),
    PolicyDocument(
      type: PolicyDocumentType.termsOfUse,
      version: '1',
      content: 'Conteúdo dos termos.',
      publishedAt: DateTime.utc(2026),
    ),
  ];
  @override
  Future<AppResult<List<PolicyDocument>>> getCurrentDocuments() async =>
      AppSuccess<List<PolicyDocument>>(documents);
  @override
  Future<AppResult<Set<String>>> getAcceptedDocumentIds(String userId) async =>
      const AppSuccess<Set<String>>(<String>{});
  @override
  Future<AppResult<void>> registerAcceptances(
    List<UserPolicyAcceptance> acceptances,
  ) async => const AppSuccess<void>(null);
}
