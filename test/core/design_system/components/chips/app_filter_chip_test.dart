import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

import '../test_pump_app.dart';

void main() {
  group('AppFilterChip', () {
    testWidgets('tapping toggles selected state', (tester) async {
      bool? lastSelected;
      await pumpApp(
        tester,
        AppFilterChip(
          label: 'Verão 2026',
          selected: false,
          onSelected: (value) => lastSelected = value,
        ),
      );

      await tester.tap(find.text('Verão 2026'));
      await tester.pump();

      expect(lastSelected, isTrue);
    });

    testWidgets('exposes selected state to assistive tech', (tester) async {
      await pumpApp(
        tester,
        AppFilterChip(label: 'Verão 2026', selected: true, onSelected: (_) {}),
      );

      final semanticsWidgets = tester.widgetList<Semantics>(
        find.byType(Semantics),
      );
      expect(
        semanticsWidgets.any((widget) => widget.properties.selected == true),
        isTrue,
      );
    });

    testWidgets('tapping the remove icon calls onRemove', (tester) async {
      var removed = false;
      await pumpApp(
        tester,
        AppFilterChip(label: 'Tamanho M', onRemove: () => removed = true),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(removed, isTrue);
    });
  });
}
