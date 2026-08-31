import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/features/orders/orders.dart';

void main() {
  group('OrderStatusHistoryTimeline', () {
    testWidgets(
      'renders every status transition chronologically, including approval '
      'and rejection',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: OrderStatusHistoryTimeline(
                entries: <OrderStatusHistoryEntry>[
                  OrderStatusHistoryEntry(
                    newStatus: OrderStatus.underReview,
                    changedAt: DateTime.utc(2026, 8, 20, 10),
                    actorId: 'rep-1',
                    previousStatus: OrderStatus.submitted,
                    reason: 'Desconto acima da política',
                  ),
                  OrderStatusHistoryEntry(
                    newStatus: OrderStatus.draft,
                    changedAt: DateTime.utc(2026, 8, 19, 9),
                    actorId: 'rep-1',
                  ),
                  OrderStatusHistoryEntry(
                    newStatus: OrderStatus.rejected,
                    changedAt: DateTime.utc(2026, 8, 21, 11),
                    actorId: 'manager-1',
                    previousStatus: OrderStatus.underReview,
                    reason: 'Margem insuficiente',
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Pedido criado'), findsOneWidget);
        expect(find.text('Enviado → Em análise'), findsOneWidget);
        expect(find.text('Em análise → Rejeitado'), findsOneWidget);
        expect(find.text('Desconto acima da política'), findsOneWidget);
        expect(find.text('Margem insuficiente'), findsOneWidget);
        expect(find.text('Rejeitado'), findsOneWidget);
        expect(find.text('Por rep-1'), findsNWidgets(2));
        expect(find.text('Por manager-1'), findsOneWidget);

        // Chronological order: creation first, approval routing second,
        // rejection last — regardless of the order entries were passed in.
        final titles = tester
            .widgetList<Text>(find.byType(Text))
            .map((widget) => widget.data)
            .whereType<String>()
            .toList();
        expect(
          titles.indexOf('Pedido criado') <
              titles.indexOf('Enviado → Em análise'),
          isTrue,
        );
        expect(
          titles.indexOf('Enviado → Em análise') <
              titles.indexOf('Em análise → Rejeitado'),
          isTrue,
        );
      },
    );

    testWidgets('shows the empty state when there is no history yet', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OrderStatusHistoryTimeline(
              entries: <OrderStatusHistoryEntry>[],
            ),
          ),
        ),
      );

      expect(
        find.text('Nenhuma alteração de status registrada ainda.'),
        findsOneWidget,
      );
    });
  });
}
