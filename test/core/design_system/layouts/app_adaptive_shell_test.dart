import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

import '../components/test_pump_app.dart';

const _destinations = <AppNavDestination>[
  AppNavDestination(
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    label: 'Início',
  ),
  AppNavDestination(
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
    label: 'Clientes',
  ),
  AppNavDestination(
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2,
    label: 'Produtos',
  ),
  AppNavDestination(
    icon: Icons.shopping_cart_outlined,
    selectedIcon: Icons.shopping_cart,
    label: 'Pedidos',
  ),
  AppNavDestination(
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart,
    label: 'Metas',
  ),
];

const _secondaryDestinations = <AppNavDestination>[
  AppNavDestination(icon: Icons.settings_outlined, label: 'Configurações'),
];

Future<void> _pumpShell(
  WidgetTester tester, {
  required double width,
  int selectedIndex = 0,
  ValueChanged<int>? onDestinationSelected,
  ValueChanged<int>? onSecondaryDestinationSelected,
  List<AppNavDestination> destinations = _destinations,
  List<AppNavDestination> secondaryDestinations = _secondaryDestinations,
  int maxMobileDestinations = 4,
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
      child: AppAdaptiveShell(
        destinations: destinations,
        secondaryDestinations: secondaryDestinations,
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected ?? (_) {},
        onSecondaryDestinationSelected: onSecondaryDestinationSelected,
        maxMobileDestinations: maxMobileDestinations,
        body: const Text('conteúdo da rota ativa'),
      ),
    ),
  );
}

void main() {
  group('AppAdaptiveShell layout per breakpoint', () {
    testWidgets('renders bottom navigation on mobile', (tester) async {
      await _pumpShell(tester, width: 375);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('conteúdo da rota ativa'), findsOneWidget);
    });

    testWidgets('renders a navigation rail on tablet', (tester) async {
      await _pumpShell(tester, width: 800);

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('conteúdo da rota ativa'), findsOneWidget);
    });

    testWidgets('renders a permanent sidebar on desktop', (tester) async {
      await _pumpShell(tester, width: 1200);

      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
      // The sidebar exposes every destination label directly (expanded by
      // default), unlike the rail's icon-first, label-on-selection layout.
      expect(find.text('Clientes'), findsOneWidget);
      expect(find.text('conteúdo da rota ativa'), findsOneWidget);
    });

    testWidgets(
      'renders the same permanent sidebar structure on large desktop',
      (tester) async {
        await _pumpShell(tester, width: 1500);

        expect(find.byType(NavigationRail), findsNothing);
        expect(find.byType(NavigationBar), findsNothing);
        expect(find.text('Clientes'), findsOneWidget);
      },
    );

    testWidgets(
      'does not break or overflow at an intermediate width between tiers',
      (tester) async {
        // 700px sits between the tablet (600) and desktop (1024)
        // breakpoints: it must stay resolved as tablet without an abrupt
        // visual break or a RenderFlex overflow.
        await _pumpShell(tester, width: 700);

        expect(find.byType(NavigationRail), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('AppAdaptiveShell shared active-route state', () {
    testWidgets(
      'reflects the same selectedIndex across mobile, tablet and desktop',
      (tester) async {
        await _pumpShell(tester, width: 375, selectedIndex: 1);
        final navigationBar = tester.widget<NavigationBar>(
          find.byType(NavigationBar),
        );
        expect(navigationBar.selectedIndex, 1);

        await _pumpShell(tester, width: 800, selectedIndex: 1);
        final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(rail.selectedIndex, 1);

        await _pumpShell(tester, width: 1200, selectedIndex: 1);
        final selectedItem = tester.widget<Semantics>(
          find.byKey(const ValueKey('app_adaptive_shell_nav_item_Clientes')),
        );
        expect(selectedItem.properties.selected, isTrue);
      },
    );

    testWidgets('reuses the exact same onDestinationSelected callback', (
      tester,
    ) async {
      final calls = <int>[];
      await _pumpShell(tester, width: 375, onDestinationSelected: calls.add);
      await tester.tap(find.text('Clientes'));
      await tester.pumpAndSettle();

      await _pumpShell(tester, width: 1200, onDestinationSelected: calls.add);
      await tester.tap(find.text('Produtos'));
      await tester.pumpAndSettle();

      expect(calls, <int>[1, 2]);
    });
  });

  group('AppAdaptiveShell mobile overflow', () {
    testWidgets('caps visible destinations and shows a "Mais" entry', (
      tester,
    ) async {
      await _pumpShell(tester, width: 375, maxMobileDestinations: 4);

      expect(find.text('Mais'), findsOneWidget);
      // The 5th primary destination ("Metas") is not directly reachable
      // from the bottom bar.
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Metas'),
        ),
        findsNothing,
      );
    });

    testWidgets('opens a sheet with the overflowed and secondary items', (
      tester,
    ) async {
      final calls = <int>[];
      final secondaryCalls = <int>[];
      await _pumpShell(
        tester,
        width: 375,
        maxMobileDestinations: 4,
        onDestinationSelected: calls.add,
        onSecondaryDestinationSelected: secondaryCalls.add,
      );

      await tester.tap(find.text('Mais'));
      await tester.pumpAndSettle();

      expect(find.text('Metas'), findsOneWidget);
      expect(find.text('Configurações'), findsOneWidget);

      await tester.tap(find.text('Configurações'));
      await tester.pumpAndSettle();

      expect(secondaryCalls, <int>[0]);
      expect(calls, isEmpty);
    });

    testWidgets(
      'tapping an overflowed primary destination reports its absolute index',
      (tester) async {
        final calls = <int>[];
        await _pumpShell(
          tester,
          width: 375,
          maxMobileDestinations: 4,
          onDestinationSelected: calls.add,
        );

        await tester.tap(find.text('Mais'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Metas'));
        await tester.pumpAndSettle();

        expect(calls, <int>[4]);
      },
    );
  });

  group('AppAdaptiveShell sidebar collapse', () {
    testWidgets('collapses and expands, hiding/showing labels', (tester) async {
      await _pumpShell(tester, width: 1200);

      expect(find.text('Clientes'), findsOneWidget);

      await tester.tap(find.byTooltip('Recolher menu'));
      await tester.pumpAndSettle();

      expect(find.text('Clientes'), findsNothing);

      await tester.tap(find.byTooltip('Expandir menu'));
      await tester.pumpAndSettle();

      expect(find.text('Clientes'), findsOneWidget);
    });
  });

  group('AppAdaptiveShell secondary destinations on desktop/tablet', () {
    testWidgets('opens the secondary sheet from the rail trailing button', (
      tester,
    ) async {
      final secondaryCalls = <int>[];
      await _pumpShell(
        tester,
        width: 800,
        onSecondaryDestinationSelected: secondaryCalls.add,
      );

      await tester.tap(find.byTooltip('Mais'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Configurações'));
      await tester.pumpAndSettle();

      expect(secondaryCalls, <int>[0]);
    });
  });
}
