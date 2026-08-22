import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

import '../test_pump_app.dart';

void main() {
  group('AppErrorState', () {
    testWidgets('renders title and a friendly message', (tester) async {
      await pumpApp(
        tester,
        const AppErrorState(
          title: 'Não foi possível carregar',
          message: 'Verifique sua conexão e tente novamente.',
        ),
      );

      expect(find.text('Não foi possível carregar'), findsOneWidget);
      expect(
        find.text('Verifique sua conexão e tente novamente.'),
        findsOneWidget,
      );
    });

    testWidgets('renders the retry action and calls onRetry', (tester) async {
      var retried = false;
      await pumpApp(
        tester,
        AppErrorState(
          title: 'Erro ao carregar pedidos',
          message: 'Tente novamente em alguns instantes.',
          retryLabel: 'Tentar novamente',
          onRetry: () => retried = true,
        ),
      );

      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();

      expect(retried, isTrue);
    });

    testWidgets('does not render a retry action when onRetry is absent', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AppErrorState(
          title: 'Erro ao carregar pedidos',
          message: 'Tente novamente em alguns instantes.',
        ),
      );

      expect(find.byType(AppButton), findsNothing);
    });
  });
}
