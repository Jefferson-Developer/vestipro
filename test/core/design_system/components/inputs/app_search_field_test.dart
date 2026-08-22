import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

import '../test_pump_app.dart';

void main() {
  group('AppSearchField', () {
    testWidgets('debounces onSearch after the configured duration', (
      tester,
    ) async {
      final queries = <String>[];
      await pumpApp(
        tester,
        AppSearchField(
          hintText: 'Buscar cliente',
          debounceDuration: const Duration(milliseconds: 200),
          onSearch: queries.add,
        ),
      );

      await tester.enterText(find.byType(TextField), 'Malwee');
      // Still inside the debounce window: no search fired yet.
      await tester.pump(const Duration(milliseconds: 100));
      expect(queries, isEmpty);

      await tester.pump(const Duration(milliseconds: 150));
      expect(queries, <String>['Malwee']);
    });

    testWidgets('shows a clear button once there is text and clears it', (
      tester,
    ) async {
      final queries = <String>[];
      await pumpApp(tester, AppSearchField(onSearch: queries.add));

      expect(find.byIcon(Icons.close), findsNothing);

      await tester.enterText(find.byType(TextField), 'Camisa');
      await tester.pump();
      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(find.text('Camisa'), findsNothing);
      expect(queries.last, isEmpty);
    });
  });
}
