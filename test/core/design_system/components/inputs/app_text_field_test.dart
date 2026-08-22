import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

import '../test_pump_app.dart';

void main() {
  group('AppTextField', () {
    testWidgets('accepts empty text without error', (tester) async {
      await pumpApp(tester, const AppTextField(label: 'Nome'));

      expect(find.text('Nome', findRichText: true), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('accepts long text and calls onChanged', (tester) async {
      String? changed;
      await pumpApp(
        tester,
        AppTextField(
          label: 'Observações',
          onChanged: (value) => changed = value,
        ),
      );

      final longText = 'A' * 500;
      await tester.enterText(find.byType(TextFormField), longText);

      expect(changed, longText);
    });

    testWidgets('shows the errorText near the field when validation fails', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AppTextField(label: 'CPF', errorText: 'CPF inválido'),
      );

      expect(find.text('CPF inválido'), findsOneWidget);
    });

    testWidgets('renders a required marker when isRequired is true', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AppTextField(label: 'Nome', isRequired: true),
      );

      expect(find.textContaining('*', findRichText: true), findsOneWidget);
    });

    testWidgets('disabled field ignores text entry', (tester) async {
      final controller = TextEditingController();
      await pumpApp(
        tester,
        AppTextField(label: 'Nome', controller: controller, isDisabled: true),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.enabled, isFalse);
    });
  });
}
