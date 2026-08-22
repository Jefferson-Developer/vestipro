import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

import '../test_pump_app.dart';

void main() {
  group('AppStatusBadge', () {
    for (final variant in AppStatusBadgeVariant.values) {
      testWidgets('${variant.name}: renders label and an icon', (tester) async {
        await pumpApp(
          tester,
          AppStatusBadge(label: 'Pedido enviado', variant: variant),
        );

        expect(find.text('Pedido enviado'), findsOneWidget);
        expect(find.byType(Icon), findsOneWidget);
      });
    }

    testWidgets('a custom icon overrides the variant default', (tester) async {
      await pumpApp(
        tester,
        const AppStatusBadge(
          label: 'Sincronizado',
          variant: AppStatusBadgeVariant.success,
          icon: Icons.cloud_done,
        ),
      );

      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    });
  });
}
