import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

import '../test_pump_app.dart';

void main() {
  group('AppButton', () {
    for (final variant in AppButtonVariant.values) {
      testWidgets('${variant.name}: tapping calls onPressed once', (
        tester,
      ) async {
        var tapCount = 0;
        await pumpApp(
          tester,
          AppButton(
            label: 'Continuar',
            variant: variant,
            onPressed: () => tapCount++,
          ),
        );

        await tester.tap(find.text('Continuar'));
        await tester.pump();

        expect(tapCount, 1);
      });
    }

    testWidgets('disabled: tapping does not call onPressed', (tester) async {
      var tapCount = 0;
      await pumpApp(
        tester,
        AppButton(
          label: 'Continuar',
          isDisabled: true,
          onPressed: () => tapCount++,
        ),
      );

      await tester.tap(find.text('Continuar'), warnIfMissed: false);
      await tester.pump();

      expect(tapCount, 0);
    });

    testWidgets(
      'loading: hides the label behind a spinner without resizing and blocks taps',
      (tester) async {
        var tapCount = 0;
        await pumpApp(
          tester,
          AppButton(
            label: 'Enviar pedido',
            isLoading: false,
            onPressed: () => tapCount++,
          ),
        );
        final idleSize = tester.getSize(find.byType(AppButton));

        await pumpApp(
          tester,
          AppButton(
            label: 'Enviar pedido',
            isLoading: true,
            onPressed: () => tapCount++,
          ),
        );
        final loadingSize = tester.getSize(find.byType(AppButton));

        expect(loadingSize, idleSize);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.tap(find.byType(AppButton), warnIfMissed: false);
        await tester.pump();

        expect(tapCount, 0);
      },
    );

    testWidgets('rapid double tap only fires onPressed once', (tester) async {
      var tapCount = 0;
      await pumpApp(
        tester,
        AppButton(label: 'Salvar', onPressed: () => tapCount++),
      );

      await tester.tap(find.text('Salvar'));
      await tester.tap(find.text('Salvar'), warnIfMissed: false);
      await tester.pump();

      expect(tapCount, 1);
    });

    testWidgets('leadingIcon renders next to the label', (tester) async {
      await pumpApp(
        tester,
        AppButton(label: 'Ligar', leadingIcon: Icons.call, onPressed: () {}),
      );

      expect(find.byIcon(Icons.call), findsOneWidget);
      expect(find.text('Ligar'), findsOneWidget);
    });

    testWidgets('meets the minimum accessible touch target size', (
      tester,
    ) async {
      await pumpApp(tester, AppButton(label: 'Continuar', onPressed: () {}));

      final size = tester.getSize(find.byType(AppButton));
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });
}
