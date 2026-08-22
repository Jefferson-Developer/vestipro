import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

import '../test_pump_app.dart';

void main() {
  group('AppEmptyState', () {
    testWidgets('renders title and description', (tester) async {
      await pumpApp(
        tester,
        const AppEmptyState(
          title: 'Nenhum cliente encontrado',
          description: 'Ajuste os filtros ou cadastre um novo cliente.',
        ),
      );

      expect(find.text('Nenhum cliente encontrado'), findsOneWidget);
      expect(
        find.text('Ajuste os filtros ou cadastre um novo cliente.'),
        findsOneWidget,
      );
    });

    testWidgets('renders the configured action and calls onAction', (
      tester,
    ) async {
      var tapped = false;
      await pumpApp(
        tester,
        AppEmptyState(
          title: 'Nenhum produto',
          actionLabel: 'Cadastrar produto',
          onAction: () => tapped = true,
        ),
      );

      await tester.tap(find.text('Cadastrar produto'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('does not render an action when none is configured', (
      tester,
    ) async {
      await pumpApp(tester, const AppEmptyState(title: 'Nenhum resultado'));

      expect(find.byType(AppButton), findsNothing);
    });
  });
}
