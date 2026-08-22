import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

import '../test_pump_app.dart';

void main() {
  const options = <AppDropdownOption<String>>[
    AppDropdownOption(value: 'sp', label: 'São Paulo'),
    AppDropdownOption(value: 'sc', label: 'Santa Catarina'),
    AppDropdownOption(value: 'rs', label: 'Rio Grande do Sul'),
  ];

  group('AppDropdown', () {
    testWidgets(
      'single selection: tapping an option calls onChanged and closes',
      (tester) async {
        Set<String>? result;
        await pumpApp(
          tester,
          AppDropdown<String>(
            options: options,
            selectedValues: const <String>{},
            label: 'Estado',
            closeSemanticLabel: 'Fechar',
            onChanged: (value) => result = value,
          ),
        );

        await tester.tap(find.byType(AppDropdown<String>));
        await tester.pumpAndSettle();

        expect(find.text('Santa Catarina'), findsOneWidget);

        await tester.tap(find.text('Santa Catarina'));
        await tester.pumpAndSettle();

        expect(result, <String>{'sc'});
      },
    );

    testWidgets('multiple selection: several options can be checked', (
      tester,
    ) async {
      Set<String>? result;
      await pumpApp(
        tester,
        AppDropdown<String>(
          options: options,
          selectedValues: const <String>{},
          multiple: true,
          label: 'Estados',
          closeSemanticLabel: 'Fechar',
          onChanged: (value) => result = value,
        ),
      );

      await tester.tap(find.byType(AppDropdown<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('São Paulo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rio Grande do Sul'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(result, <String>{'sp', 'rs'});
    });

    testWidgets('internal search narrows down the option list', (tester) async {
      await pumpApp(
        tester,
        AppDropdown<String>(
          options: options,
          selectedValues: const <String>{},
          label: 'Estado',
          closeSemanticLabel: 'Fechar',
          searchHintText: 'Buscar estado',
          onChanged: (_) {},
        ),
      );

      await tester.tap(find.byType(AppDropdown<String>));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Santa');
      await tester.pumpAndSettle();

      expect(find.text('Santa Catarina'), findsOneWidget);
      expect(find.text('São Paulo'), findsNothing);
      expect(find.text('Rio Grande do Sul'), findsNothing);
    });
  });
}
