import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

import '../test_pump_app.dart';

void main() {
  group('AppModal', () {
    testWidgets('show renders the title and body', (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => AppButton(
            label: 'Abrir',
            onPressed: () => AppModal.show<void>(
              context: context,
              title: 'Detalhes do pedido',
              body: const Text('Corpo do modal'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Detalhes do pedido'), findsOneWidget);
      expect(find.text('Corpo do modal'), findsOneWidget);
    });

    testWidgets('closes when the close button is tapped', (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => AppButton(
            label: 'Abrir',
            onPressed: () => AppModal.show<void>(
              context: context,
              title: 'Detalhes do pedido',
              body: const Text('Corpo do modal'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Detalhes do pedido'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Detalhes do pedido'), findsNothing);
    });

    testWidgets('closes when the primary action is tapped', (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => AppButton(
            label: 'Abrir',
            onPressed: () => AppModal.show<void>(
              context: context,
              title: 'Detalhes do pedido',
              body: const Text('Corpo do modal'),
              primaryAction: AppModalAction(
                label: 'Confirmar',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(find.text('Detalhes do pedido'), findsNothing);
    });

    testWidgets('closes on Esc on the Web/desktop shortcut', (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => AppButton(
            label: 'Abrir',
            onPressed: () => AppModal.show<void>(
              context: context,
              title: 'Detalhes do pedido',
              body: const Text('Corpo do modal'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Detalhes do pedido'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Detalhes do pedido'), findsNothing);
    });

    testWidgets('returns focus to the trigger after closing', (tester) async {
      final triggerNode = FocusNode(debugLabel: 'trigger');
      addTearDown(triggerNode.dispose);
      late BuildContext capturedContext;

      await pumpApp(
        tester,
        Builder(
          builder: (context) {
            capturedContext = context;
            return Focus(
              focusNode: triggerNode,
              child: const SizedBox(width: 10, height: 10),
            );
          },
        ),
      );

      triggerNode.requestFocus();
      await tester.pump();
      expect(triggerNode.hasFocus, isTrue);

      final future = AppModal.show<void>(
        context: capturedContext,
        title: 'Detalhes do pedido',
        body: const Text('Corpo do modal'),
      );
      await tester.pumpAndSettle();
      expect(triggerNode.hasFocus, isFalse);

      Navigator.of(capturedContext).pop();
      await tester.pumpAndSettle();
      await future;

      expect(triggerNode.hasFocus, isTrue);
    });
  });
}
