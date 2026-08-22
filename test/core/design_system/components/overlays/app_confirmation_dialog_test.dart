import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

import '../test_pump_app.dart';

void main() {
  group('AppConfirmationDialog', () {
    testWidgets(
      'resolves to true only after the destructive action is confirmed',
      (tester) async {
        bool? result;
        await pumpApp(
          tester,
          Builder(
            builder: (context) => AppButton(
              label: 'Excluir cliente',
              onPressed: () async {
                result = await AppConfirmationDialog.show(
                  context: context,
                  title: 'Excluir cliente?',
                  message: 'Esta ação remove o cliente e seu histórico.',
                  confirmLabel: 'Excluir',
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Excluir cliente'));
        await tester.pumpAndSettle();

        // Dismissing via the barrier (an accidental tap) must never confirm
        // the destructive action.
        expect(find.text('Excluir cliente?'), findsOneWidget);

        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(result, isFalse);
      },
    );

    testWidgets('resolves to false when cancel is tapped', (tester) async {
      bool? result;
      await pumpApp(
        tester,
        Builder(
          builder: (context) => AppButton(
            label: 'Excluir cliente',
            onPressed: () async {
              result = await AppConfirmationDialog.show(
                context: context,
                title: 'Excluir cliente?',
                message: 'Esta ação remove o cliente e seu histórico.',
                confirmLabel: 'Excluir',
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Excluir cliente'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('resolves to true only when the confirm button is tapped', (
      tester,
    ) async {
      bool? result;
      await pumpApp(
        tester,
        Builder(
          builder: (context) => AppButton(
            label: 'Excluir cliente',
            onPressed: () async {
              result = await AppConfirmationDialog.show(
                context: context,
                title: 'Excluir cliente?',
                message: 'Esta ação remove o cliente e seu histórico.',
                confirmLabel: 'Excluir',
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Excluir cliente'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });
}
