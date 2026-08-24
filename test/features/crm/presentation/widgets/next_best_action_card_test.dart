import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/features/crm/crm.dart';

void main() {
  group('NextBestActionCard', () {
    testWidgets('shows reason, evidence, priority and triggers CTA', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: NextBestActionCard(
              action: _action(),
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Registrar ligacao de acompanhamento'), findsOneWidget);
      expect(find.text('Cliente sem contato ha 45 dias.'), findsOneWidget);
      expect(find.text('Ultima atividade CRM em 10/07/2026.'), findsOneWidget);
      expect(find.text('Prioridade media'), findsOneWidget);

      await tester.tap(find.text('Registrar ligacao'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}

NextBestAction _action() {
  return NextBestAction(
    id: 'nba-1',
    organizationId: 'org-1',
    customerId: 'customer-1',
    customerName: 'Atacado Alfa',
    type: NextBestActionType.callCustomer,
    priority: NextBestActionPriority.medium,
    suggestedAction: 'Registrar ligacao de acompanhamento',
    reason: 'Cliente sem contato ha 45 dias.',
    evidence: 'Ultima atividade CRM em 10/07/2026.',
    createdAt: DateTime.utc(2026, 8, 24),
    suggestedActivityType: CrmActivityType.phoneCall,
  );
}
