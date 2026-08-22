import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

import '../test_pump_app.dart';

// Golden fixtures deliberately omit `imageUrl`: exercising
// `CachedNetworkImage`'s real network/disk-cache path needs platform
// channels (`path_provider`) that are not available under `flutter test`.
// `AppProductGrid`'s image fallback (see `app_product_grid_test.dart`) is
// itself a rendered state worth a golden — every card below renders it.
const _products = <AppProductCardData>[
  AppProductCardData(
    id: 'sku-1',
    name: 'Camisa Social Slim',
    brandOrCollection: 'Coleção Verão',
    availableColorSwatches: [Colors.blue, Colors.white, Colors.black],
    priceLabel: 'R\$ 189,90',
    previousPriceLabel: 'R\$ 229,90',
    badgeLabels: ['Lançamento'],
  ),
  AppProductCardData(
    id: 'sku-2',
    name: 'Calça Alfaiataria',
    brandOrCollection: 'Coleção Verão',
    availability: AppProductAvailability.futureStock,
  ),
];

const _sizeColumns = <AppSizeGridColumn>[
  AppSizeGridColumn(id: 'p', label: 'P'),
  AppSizeGridColumn(id: 'm', label: 'M'),
  AppSizeGridColumn(id: 'g', label: 'G'),
];

const _sizeRows = <AppSizeGridRow>[
  AppSizeGridRow(
    id: 'navy',
    label: 'Azul marinho',
    colorSwatch: Color(0xFF102A43),
    cells: {
      'p': AppSizeGridCell(quantity: 2),
      'm': AppSizeGridCell(quantity: 5),
      'g': AppSizeGridCell(
        availability: AppSizeGridCellAvailability.unavailable,
      ),
    },
  ),
  AppSizeGridRow(
    id: 'white',
    label: 'Branco',
    colorSwatch: Colors.white,
    cells: {
      'p': AppSizeGridCell(quantity: 1),
      'm': AppSizeGridCell(
        availability: AppSizeGridCellAvailability.futureStock,
      ),
      'g': AppSizeGridCell(),
    },
  ),
];

const _swatchOptions = <AppColorSwatchOption>[
  AppColorSwatchOption(
    id: 'navy',
    label: 'Azul marinho',
    color: Color(0xFF102A43),
  ),
  AppColorSwatchOption(id: 'white', label: 'Branco', color: Colors.white),
  AppColorSwatchOption(
    id: 'red',
    label: 'Vermelho',
    color: Color(0xFFB3261E),
    availability: AppColorAvailability.unavailable,
  ),
  AppColorSwatchOption(
    id: 'yellow',
    label: 'Amarelo',
    color: Color(0xFFF2C400),
    availability: AppColorAvailability.futureStock,
  ),
];

/// Golden coverage for the catalog/grade components — [AppProductGrid],
/// [AppSizeGrid] and [AppColorSwatchSelector] — across mobile, tablet and
/// desktop widths, per TASK-024's acceptance criteria. Run
/// `flutter test --update-goldens` after an intentional visual change to
/// this set of components.
void main() {
  Future<void> expectGolden(
    WidgetTester tester,
    Widget child,
    String name, {
    required double width,
    double height = 760,
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
        child: SizedBox(width: width, child: child),
      ),
    );
    await tester.pump();
    await expectLater(find.byKey(Key(name)), matchesGoldenFile('$name.png'));
  }

  group('AppProductGrid goldens', () {
    testWidgets('mobile', (tester) async {
      await expectGolden(
        tester,
        AppProductGrid(products: _products, onProductTap: (_) {}),
        'app_product_grid_mobile',
        width: 375,
      );
    });

    testWidgets('tablet', (tester) async {
      await expectGolden(
        tester,
        AppProductGrid(products: _products, onProductTap: (_) {}),
        'app_product_grid_tablet',
        width: 800,
      );
    });

    testWidgets('desktop', (tester) async {
      await expectGolden(
        tester,
        AppProductGrid(products: _products, onProductTap: (_) {}),
        'app_product_grid_desktop',
        width: 1200,
      );
    });
  });

  group('AppSizeGrid goldens', () {
    testWidgets('mobile', (tester) async {
      await expectGolden(
        tester,
        AppSizeGrid(
          columns: _sizeColumns,
          rows: _sizeRows,
          onQuantityChanged: (_, _, _) {},
        ),
        'app_size_grid_mobile',
        width: 375,
      );
    });

    testWidgets('tablet', (tester) async {
      await expectGolden(
        tester,
        AppSizeGrid(
          columns: _sizeColumns,
          rows: _sizeRows,
          onQuantityChanged: (_, _, _) {},
        ),
        'app_size_grid_tablet',
        width: 800,
      );
    });

    testWidgets('desktop', (tester) async {
      await expectGolden(
        tester,
        AppSizeGrid(
          columns: _sizeColumns,
          rows: _sizeRows,
          onQuantityChanged: (_, _, _) {},
        ),
        'app_size_grid_desktop',
        width: 1200,
      );
    });
  });

  group('AppColorSwatchSelector goldens', () {
    testWidgets('mobile', (tester) async {
      await expectGolden(
        tester,
        AppColorSwatchSelector(
          options: _swatchOptions,
          selectedId: 'navy',
          onSelected: (_) {},
        ),
        'app_color_swatch_selector_mobile',
        width: 375,
        height: 200,
      );
    });

    testWidgets('tablet', (tester) async {
      await expectGolden(
        tester,
        AppColorSwatchSelector(
          options: _swatchOptions,
          selectedId: 'navy',
          onSelected: (_) {},
        ),
        'app_color_swatch_selector_tablet',
        width: 800,
        height: 200,
      );
    });

    testWidgets('desktop', (tester) async {
      await expectGolden(
        tester,
        AppColorSwatchSelector(
          options: _swatchOptions,
          selectedId: 'navy',
          onSelected: (_) {},
        ),
        'app_color_swatch_selector_desktop',
        width: 1200,
        height: 200,
      );
    });
  });
}
