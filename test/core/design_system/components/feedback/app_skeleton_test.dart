import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

import '../test_pump_app.dart';

void main() {
  group('AppSkeleton', () {
    testWidgets('line/block/card constructors size the placeholder', (
      tester,
    ) async {
      await pumpApp(tester, const AppSkeleton.line(width: 120));
      expect(tester.getSize(find.byType(AppSkeleton)).width, 120);

      await pumpApp(tester, const AppSkeleton.block(width: 64, height: 64));
      expect(tester.getSize(find.byType(AppSkeleton)), const Size(64, 64));

      await pumpApp(tester, const AppSkeleton.card(width: 200, height: 120));
      expect(tester.getSize(find.byType(AppSkeleton)), const Size(200, 120));
    });

    testWidgets('animates opacity without throwing', (tester) async {
      await pumpApp(tester, const AppSkeleton.line(width: 100));

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });
  });
}
