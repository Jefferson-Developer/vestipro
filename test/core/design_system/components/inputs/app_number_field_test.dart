import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

import '../test_pump_app.dart';

void main() {
  group('AppNumberField', () {
    testWidgets('uses a numeric keyboard type', (tester) async {
      await pumpApp(tester, const AppNumberField(label: 'Quantidade'));

      final field = tester.widget<EditableText>(find.byType(EditableText));
      expect(field.keyboardType, TextInputType.number);
    });

    testWidgets('strips non-digit characters by default', (tester) async {
      String? changed;
      await pumpApp(
        tester,
        AppNumberField(
          label: 'Quantidade',
          onChanged: (value) => changed = value,
        ),
      );

      await tester.enterText(find.byType(TextFormField), '12a3b');

      expect(changed, '123');
    });

    testWidgets('allows a decimal separator when allowDecimal is true', (
      tester,
    ) async {
      String? changed;
      await pumpApp(
        tester,
        AppNumberField(
          label: 'Peso',
          allowDecimal: true,
          onChanged: (value) => changed = value,
        ),
      );

      await tester.enterText(find.byType(TextFormField), '12,5');

      expect(changed, '12,5');
    });

    testWidgets('shows errorText near the field', (tester) async {
      await pumpApp(
        tester,
        const AppNumberField(
          label: 'Quantidade',
          errorText: 'Quantidade excede o estoque',
        ),
      );

      expect(find.text('Quantidade excede o estoque'), findsOneWidget);
    });
  });
}
