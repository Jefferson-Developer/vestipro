import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

import '../test_pump_app.dart';

void main() {
  group('AppTooltip', () {
    testWidgets('shows the message on long-press (touch fallback)', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AppTooltip(
          message: 'Preço sujeito à tabela vigente',
          child: Icon(Icons.info_outline),
        ),
      );

      expect(find.text('Preço sujeito à tabela vigente'), findsNothing);

      await tester.longPress(find.byIcon(Icons.info_outline));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Preço sujeito à tabela vigente'), findsOneWidget);
    });

    testWidgets('helpIcon renders a reachable info icon carrying the message', (
      tester,
    ) async {
      await pumpApp(
        tester,
        AppTooltip.helpIcon(message: 'Como calculamos esse indicador'),
      );

      expect(find.byIcon(Icons.help_outline), findsOneWidget);

      await tester.longPress(find.byIcon(Icons.help_outline));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Como calculamos esse indicador'), findsOneWidget);
    });
  });
}
