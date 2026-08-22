import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

import '../test_pump_app.dart';

void main() {
  group('AppIconButton', () {
    testWidgets('tapping calls onPressed once', (tester) async {
      var tapCount = 0;
      await pumpApp(
        tester,
        AppIconButton(
          icon: Icons.call,
          semanticLabel: 'Ligar para o cliente',
          onPressed: () => tapCount++,
        ),
      );

      await tester.tap(find.byIcon(Icons.call));
      await tester.pump();

      expect(tapCount, 1);
    });

    testWidgets('exposes the required semanticLabel to assistive tech', (
      tester,
    ) async {
      await pumpApp(
        tester,
        AppIconButton(
          icon: Icons.call,
          semanticLabel: 'Ligar para o cliente',
          onPressed: () {},
        ),
      );

      expect(find.bySemanticsLabel('Ligar para o cliente'), findsOneWidget);
    });

    testWidgets('loading blocks taps and shows a spinner', (tester) async {
      var tapCount = 0;
      await pumpApp(
        tester,
        AppIconButton(
          icon: Icons.call,
          semanticLabel: 'Ligar',
          isLoading: true,
          onPressed: () => tapCount++,
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byType(AppIconButton), warnIfMissed: false);
      await tester.pump();

      expect(tapCount, 0);
    });

    testWidgets('meets the minimum accessible touch target size', (
      tester,
    ) async {
      await pumpApp(
        tester,
        AppIconButton(
          icon: Icons.call,
          semanticLabel: 'Ligar',
          onPressed: () {},
        ),
      );

      final size = tester.getSize(find.byType(AppIconButton));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });
}
