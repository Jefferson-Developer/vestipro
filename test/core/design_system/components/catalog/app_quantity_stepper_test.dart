import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

import '../test_pump_app.dart';

void main() {
  group('AppQuantityStepper', () {
    testWidgets('increments by step when the "+" control is tapped', (
      tester,
    ) async {
      int? nextQuantity;

      await pumpApp(
        tester,
        AppQuantityStepper(
          quantity: 3,
          onChanged: (value) => nextQuantity = value,
        ),
      );

      await tester.tap(find.bySemanticsLabel('Aumentar quantidade'));
      await tester.pump();

      expect(nextQuantity, 4);
    });

    testWidgets('decrements by step when the "-" control is tapped', (
      tester,
    ) async {
      int? nextQuantity;

      await pumpApp(
        tester,
        AppQuantityStepper(
          quantity: 3,
          onChanged: (value) => nextQuantity = value,
        ),
      );

      await tester.tap(find.bySemanticsLabel('Diminuir quantidade'));
      await tester.pump();

      expect(nextQuantity, 2);
    });

    testWidgets('never goes below minQuantity — the "-" control disables', (
      tester,
    ) async {
      var called = false;

      await pumpApp(
        tester,
        AppQuantityStepper(
          quantity: 0,
          minQuantity: 0,
          onChanged: (_) => called = true,
        ),
      );

      await tester.tap(find.bySemanticsLabel('Diminuir quantidade'));
      await tester.pump();

      expect(called, isFalse);
    });

    testWidgets('never goes above maxQuantity — the "+" control disables', (
      tester,
    ) async {
      var called = false;

      await pumpApp(
        tester,
        AppQuantityStepper(
          quantity: 5,
          maxQuantity: 5,
          onChanged: (_) => called = true,
        ),
      );

      await tester.tap(find.bySemanticsLabel('Aumentar quantidade'));
      await tester.pump();

      expect(called, isFalse);
    });

    testWidgets('commits a directly-typed value clamped to maxQuantity', (
      tester,
    ) async {
      int? nextQuantity;

      await pumpApp(
        tester,
        AppQuantityStepper(
          quantity: 2,
          maxQuantity: 10,
          onChanged: (value) => nextQuantity = value,
        ),
      );

      await tester.enterText(find.byType(TextField), '99');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(nextQuantity, 10);
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('commits a directly-typed value clamped to minQuantity', (
      tester,
    ) async {
      int? nextQuantity;

      await pumpApp(
        tester,
        AppQuantityStepper(
          quantity: 5,
          minQuantity: 1,
          onChanged: (value) => nextQuantity = value,
        ),
      );

      await tester.enterText(find.byType(TextField), '0');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(nextQuantity, 1);
    });

    testWidgets('does not call onChanged while disabled', (tester) async {
      var called = false;

      await pumpApp(
        tester,
        AppQuantityStepper(
          quantity: 3,
          isDisabled: true,
          onChanged: (_) => called = true,
        ),
      );

      await tester.tap(find.bySemanticsLabel('Aumentar quantidade'));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Diminuir quantidade'));
      await tester.pump();

      expect(called, isFalse);
    });
  });
}
