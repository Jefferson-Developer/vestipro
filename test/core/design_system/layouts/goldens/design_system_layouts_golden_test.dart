import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

import '../../components/test_pump_app.dart';

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
];

const _secondaryDestinations = <AppNavDestination>[
  AppNavDestination(icon: Icons.settings_outlined, label: 'Configurações'),
];

/// Golden coverage for the layout primitives — [AppAdaptiveShell] and
/// [AppAdminPageLayout] — across mobile, tablet, desktop and large-desktop
/// widths, per TASK-025's acceptance criteria. Run
/// `flutter test --update-goldens` after an intentional visual change to
/// this set of widgets.
void main() {
  Future<void> expectGolden(
    WidgetTester tester,
    Widget child,
    String name, {
    required double width,
    double height = 700,
  }) async {
    final view = tester.view;
    view.physicalSize = Size(width + 80, height);
    view.devicePixelRatio = 1.0;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);

    await pumpApp(
      tester,
      RepaintBoundary(
        key: Key(name),
        child: SizedBox(width: width, height: height, child: child),
      ),
    );
    await tester.pump();
    await expectLater(find.byKey(Key(name)), matchesGoldenFile('$name.png'));
  }

  Widget buildShell({int selectedIndex = 1}) {
    return AppAdaptiveShell(
      destinations: _destinations,
      secondaryDestinations: _secondaryDestinations,
      selectedIndex: selectedIndex,
      onDestinationSelected: (_) {},
      onSecondaryDestinationSelected: (_) {},
      body: const Center(child: Text('Conteúdo da rota ativa')),
    );
  }

  group('AppAdaptiveShell goldens', () {
    testWidgets('mobile', (tester) async {
      await expectGolden(
        tester,
        buildShell(),
        'app_adaptive_shell_mobile',
        width: 375,
      );
    });

    testWidgets('tablet', (tester) async {
      await expectGolden(
        tester,
        buildShell(),
        'app_adaptive_shell_tablet',
        width: 800,
      );
    });

    testWidgets('desktop', (tester) async {
      await expectGolden(
        tester,
        buildShell(),
        'app_adaptive_shell_desktop',
        width: 1200,
      );
    });

    testWidgets('largeDesktop', (tester) async {
      await expectGolden(
        tester,
        buildShell(),
        'app_adaptive_shell_large_desktop',
        width: 1500,
      );
    });
  });

  group('AppAdminPageLayout goldens', () {
    Widget buildLayout() {
      return AppAdminPageLayout(
        title: 'Clientes',
        actions: const [Icon(Icons.add)],
        filtersBuilder: (context) => const Text('Formulário de filtros'),
        content: const Text('Lista de clientes'),
      );
    }

    testWidgets('mobile shows a filter button', (tester) async {
      await expectGolden(
        tester,
        buildLayout(),
        'app_admin_page_layout_mobile',
        width: 375,
      );
    });

    testWidgets('desktop shows a permanent filters panel', (tester) async {
      await expectGolden(
        tester,
        buildLayout(),
        'app_admin_page_layout_desktop',
        width: 1200,
      );
    });
  });
}
