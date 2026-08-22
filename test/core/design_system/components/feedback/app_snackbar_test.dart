import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

import '../test_pump_app.dart';

void main() {
  group('AppSnackbar', () {
    testWidgets('show renders the message', (tester) async {
      await pumpApp(tester, const SizedBox());
      final context = tester.element(find.byType(SizedBox));

      AppSnackbar.show(context, message: 'Rascunho salvo');
      await tester.pump();

      expect(find.text('Rascunho salvo'), findsOneWidget);
    });

    testWidgets(
      'enqueues multiple messages fired in sequence instead of overlapping',
      (tester) async {
        await pumpApp(tester, const SizedBox());
        final context = tester.element(find.byType(SizedBox));

        AppSnackbar.show(
          context,
          message: 'Primeira mensagem',
          duration: const Duration(seconds: 1),
        );
        AppSnackbar.show(
          context,
          message: 'Segunda mensagem',
          duration: const Duration(seconds: 1),
        );
        await tester.pump();

        expect(find.text('Primeira mensagem'), findsOneWidget);
        expect(find.text('Segunda mensagem'), findsNothing);

        // Advance past the first snackbar's entrance animation, its visible
        // duration and its exit animation, in discrete steps (mirrors how
        // SnackBar's own Timer-driven lifecycle is exercised in tests): the
        // queued second message must only appear afterwards, never at the
        // same time as the first.
        await tester.pump(const Duration(milliseconds: 750));
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(milliseconds: 750));
        await tester.pump();

        expect(find.text('Primeira mensagem'), findsNothing);
        expect(find.text('Segunda mensagem'), findsOneWidget);
      },
    );

    testWidgets('renders the action button when provided', (tester) async {
      await pumpApp(tester, const SizedBox());
      final context = tester.element(find.byType(SizedBox));
      var actionTapped = false;

      AppSnackbar.show(
        context,
        message: 'Pedido enviado para aprovação',
        actionLabel: 'Desfazer',
        onAction: () => actionTapped = true,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      await tester.tap(find.text('Desfazer'));
      await tester.pump();

      expect(actionTapped, isTrue);
    });
  });
}
