import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

import '../test_pump_app.dart';

void main() {
  group('AppCheckbox', () {
    testWidgets('renders the label and starts unchecked', (tester) async {
      await pumpApp(
        tester,
        AppCheckbox(value: false, onChanged: (_) {}, label: 'Aceito os termos'),
      );

      expect(find.text('Aceito os termos'), findsOneWidget);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    });

    testWidgets('calls onChanged with the toggled value on tap', (
      tester,
    ) async {
      bool? toggledTo;
      await pumpApp(
        tester,
        AppCheckbox(
          value: false,
          onChanged: (value) => toggledTo = value,
          label: 'Aceito os termos',
        ),
      );

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(toggledTo, isTrue);
    });

    testWidgets('a disabled checkbox ignores taps', (tester) async {
      bool? toggledTo;
      await pumpApp(
        tester,
        AppCheckbox(
          value: false,
          isDisabled: true,
          onChanged: (value) => toggledTo = value,
          label: 'Aceito os termos',
        ),
      );

      await tester.tap(find.byType(Checkbox), warnIfMissed: false);
      await tester.pump();

      expect(toggledTo, isNull);
    });

    testWidgets('a null onChanged also disables the control', (tester) async {
      await pumpApp(
        tester,
        const AppCheckbox(
          value: false,
          onChanged: null,
          label: 'Aceito os termos',
        ),
      );

      expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);
    });

    testWidgets('shows the errorText below the row when present', (
      tester,
    ) async {
      await pumpApp(
        tester,
        AppCheckbox(
          value: false,
          onChanged: (_) {},
          label: 'Aceito os termos',
          errorText: 'É necessário aceitar os termos.',
        ),
      );

      expect(find.text('É necessário aceitar os termos.'), findsOneWidget);
    });

    testWidgets('labelWidget overrides the plain-text label', (tester) async {
      await pumpApp(
        tester,
        AppCheckbox(
          value: false,
          onChanged: (_) {},
          label: 'Aceito os termos',
          labelWidget: const Text('Rótulo customizado'),
        ),
      );

      expect(find.text('Rótulo customizado'), findsOneWidget);
      expect(find.text('Aceito os termos'), findsNothing);
    });
  });
}
