import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

import '../test_pump_app.dart';

void main() {
  group('AppNotificationListTile', () {
    testWidgets(
      'a critical notification renders the "Crítico" badge with an icon, '
      'never relying on color alone (TASK-153)',
      (tester) async {
        await pumpApp(
          tester,
          const AppNotificationListTile(
            title: 'Meta em risco alto',
            body: 'Seu ritmo atual está bem abaixo do necessário.',
            category: AppNotificationTileCategory.commercial,
            timestampLabel: '05/09/2026 10:00',
            isUnread: true,
            isCritical: true,
          ),
        );

        expect(find.text('Crítico'), findsOneWidget);
        expect(find.byIcon(Icons.priority_high), findsOneWidget);
      },
    );

    testWidgets(
      'an informative notification never renders the "Crítico" badge',
      (tester) async {
        await pumpApp(
          tester,
          const AppNotificationListTile(
            title: 'Meta próxima de ser atingida',
            body: 'Você está perto de bater esta meta.',
            category: AppNotificationTileCategory.commercial,
            timestampLabel: '05/09/2026 10:00',
            isUnread: true,
          ),
        );

        expect(find.text('Crítico'), findsNothing);
        expect(find.byIcon(Icons.priority_high), findsNothing);
      },
    );

    testWidgets(
      'the semantic label calls out a critical notification explicitly',
      (tester) async {
        await pumpApp(
          tester,
          const AppNotificationListTile(
            title: 'Pedido rejeitado',
            body: 'O pedido 123 foi rejeitado.',
            category: AppNotificationTileCategory.commercial,
            timestampLabel: '05/09/2026 10:00',
            isUnread: true,
            isCritical: true,
          ),
        );

        final semantics = tester.getSemantics(
          find.byType(AppNotificationListTile),
        );
        expect(semantics.label, contains('crítico'));
      },
    );
  });
}
