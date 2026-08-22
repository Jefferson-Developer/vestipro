import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

import '../components/test_pump_app.dart';

Future<void> _pumpLayout(
  WidgetTester tester, {
  required double width,
  WidgetBuilder? filtersBuilder,
}) {
  // The default flutter_test surface is only 800x600 logical pixels: wide
  // enough for mobile/tablet fixtures, but too narrow for desktop/large
  // desktop ones. Resizing it here (instead of only the requested
  // SizedBox) is what actually lets AppResponsiveBuilder's LayoutBuilder
  // see the full requested width.
  final view = tester.view;
  view.physicalSize = Size(width + 100, 800);
  view.devicePixelRatio = 1.0;
  addTearDown(view.resetPhysicalSize);
  addTearDown(view.resetDevicePixelRatio);

  return pumpApp(
    tester,
    SizedBox(
      width: width,
      height: 700,
      child: AppAdminPageLayout(
        title: 'Clientes',
        filtersBuilder: filtersBuilder,
        content: const Text('lista de clientes'),
      ),
    ),
  );
}

void main() {
  group('AppAdminPageLayout without filters', () {
    testWidgets('shows only the header and the content on any breakpoint', (
      tester,
    ) async {
      await _pumpLayout(tester, width: 1200);

      expect(find.text('Clientes'), findsOneWidget);
      expect(find.text('lista de clientes'), findsOneWidget);
      expect(find.byIcon(Icons.filter_list), findsNothing);
    });
  });

  group('AppAdminPageLayout with filters on mobile/tablet', () {
    testWidgets(
      'shows a filter button that opens the filters form in a bottom sheet',
      (tester) async {
        await _pumpLayout(
          tester,
          width: 375,
          filtersBuilder: (context) => const Text('formulário de filtros'),
        );

        expect(find.byIcon(Icons.filter_list), findsOneWidget);
        // No permanent side panel: the filters form is not on screen yet.
        expect(find.text('formulário de filtros'), findsNothing);

        await tester.tap(find.byIcon(Icons.filter_list));
        await tester.pumpAndSettle();

        expect(find.text('formulário de filtros'), findsOneWidget);
      },
    );

    testWidgets('keeps showing a filter button on tablet', (tester) async {
      await _pumpLayout(
        tester,
        width: 800,
        filtersBuilder: (context) => const Text('formulário de filtros'),
      );

      expect(find.byIcon(Icons.filter_list), findsOneWidget);
      expect(find.text('formulário de filtros'), findsNothing);
    });
  });

  group('AppAdminPageLayout with filters on desktop/largeDesktop', () {
    testWidgets(
      'shows the filters form in a permanent side panel, no filter button',
      (tester) async {
        await _pumpLayout(
          tester,
          width: 1200,
          filtersBuilder: (context) => const Text('formulário de filtros'),
        );

        expect(find.byIcon(Icons.filter_list), findsNothing);
        expect(find.text('formulário de filtros'), findsOneWidget);
        expect(find.text('lista de clientes'), findsOneWidget);
      },
    );

    testWidgets('keeps the side panel on large desktop', (tester) async {
      await _pumpLayout(
        tester,
        width: 1500,
        filtersBuilder: (context) => const Text('formulário de filtros'),
      );

      expect(find.byIcon(Icons.filter_list), findsNothing);
      expect(find.text('formulário de filtros'), findsOneWidget);
    });
  });
}
