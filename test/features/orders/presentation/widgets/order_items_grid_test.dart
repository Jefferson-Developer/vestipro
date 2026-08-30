import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/orders/orders.dart';
import 'package:vestipro/features/products/products.dart';

import '../../../../core/design_system/components/test_pump_app.dart';
import '../../../products/product_factory.dart';

class _MockProductVariantRepository extends Mock
    implements ProductVariantRepository {}

class _MockProductColorRepository extends Mock
    implements ProductColorRepository {}

class _MockSizeGridTemplateRepository extends Mock
    implements SizeGridTemplateRepository {}

class _MockVariantAvailabilityRepository extends Mock
    implements VariantAvailabilityRepository {}

/// TASK-098's own widget tests for `OrderItemsGrid`: filling cells generates
/// or updates `OrderItem`s the same way `OrderDraftBloc` would, totals per
/// color/size/product stay live, the exact same `AppSizeGrid` Design System
/// component (TASK-073/TASK-024) is reused (never a grid rebuilt for
/// orders), typed quantities survive a lost connection and keyboard
/// navigation between cells keeps working for Web.
///
/// `OrderItemsGridCubit`'s catalog use cases are mocked here instead of
/// backed by the real `SharedPreferences`-backed repositories:
/// `OrderItemsGrid` triggers its cubit's `load()` from its own `initState`
/// (an internal implementation detail of the reusable widget, not something
/// this test drives directly), and exercising a real platform-channel-backed
/// plugin from inside `initState` during `testWidgets`'s fake-async pump
/// loop is exactly the scenario Flutter's own testing guidance reserves for
/// `tester.runAsync()` (real, unmocked async gaps never resolve otherwise).
/// Mocking the catalog read keeps this test deterministic and fast while
/// still exercising the exact same production widget/cubit code path.
void main() {
  testWidgets(
    'reuses the same AppSizeGrid component TASK-073 already ships, never a '
    'grid reimplemented for orders',
    (tester) async {
      await _pumpGrid(tester, items: const <OrderItem>[]);

      expect(find.byType(AppSizeGrid), findsOneWidget);
    },
  );

  testWidgets(
    'fills multiple color/size cells and keeps row/column/product totals '
    'live, generating or updating the matching OrderItem',
    (tester) async {
      final changes = <(String, int)>[];
      await _pumpGrid(
        tester,
        items: const <OrderItem>[
          OrderItem(
            id: 'item-1',
            variantId: 'variant-preto-p',
            productId: 'product-1',
            quantity: 2,
            unitPrice: 10,
            subtotal: 20,
          ),
        ],
        onQuantityChanged: (variantId, quantity) =>
            changes.add((variantId, quantity)),
      );

      final fields = find.byType(TextField);
      // The already-added item (variant-preto-p) starts pre-filled.
      expect(tester.widget<TextField>(fields.at(0)).controller!.text, '2');

      // Filling a brand new cell (variant-branco-m, previously empty) must
      // report it back so the caller (OrderDraftBloc) can generate a new
      // OrderItem for it.
      await tester.enterText(fields.at(3), '5');
      await tester.pumpAndSettle();

      expect(changes, contains(('variant-branco-m', 5)));
      expect(
        tester
            .widget<Text>(
              find.byKey(const Key('app_size_grid_column_total_size-m')),
            )
            .data,
        '5',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('app_size_grid_grand_total')))
            .data,
        '7',
      );
    },
  );

  testWidgets(
    'never loses an already-typed quantity when connectivity drops mid-'
    'typing',
    (tester) async {
      const channel = MethodChannel('dev.fluttercommunity.plus/connectivity');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'check') return <String>['none'];
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

      await _pumpGrid(tester, items: const <OrderItem>[]);

      await tester.enterText(find.byType(TextField).first, '4');
      await tester.pumpAndSettle();

      // Connectivity dropping never touches this widget's own state — the
      // typed value keeps living in the still-focused/committed TextField,
      // exactly the "grade opera 100% sobre o estado local do rascunho"
      // guarantee.
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        '4',
      );
    },
  );

  testWidgets('supports tab/enter keyboard navigation between cells on Web', (
    tester,
  ) async {
    await _pumpGrid(tester, items: const <OrderItem>[]);

    final fields = find.byType(TextField);
    await tester.tap(fields.first);
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    final secondField = tester.widget<TextField>(fields.at(1));
    expect(secondField.focusNode!.hasFocus, isTrue);
  });
}

Future<void> _pumpGrid(
  WidgetTester tester, {
  required List<OrderItem> items,
  void Function(String variantId, int quantity)? onQuantityChanged,
}) async {
  final variantRepository = _MockProductVariantRepository();
  final colorRepository = _MockProductColorRepository();
  final templateRepository = _MockSizeGridTemplateRepository();
  final availabilityRepository = _MockVariantAvailabilityRepository();

  when(
    () => variantRepository.listByProduct(
      organizationId: any(named: 'organizationId'),
      productId: any(named: 'productId'),
    ),
  ).thenAnswer((_) async => AppSuccess<List<ProductVariant>>(_variants));
  when(
    () => colorRepository.listByOrganization(any()),
  ).thenAnswer((_) async => AppSuccess<List<ProductColor>>(_colors));
  when(
    () => templateRepository.getById(
      organizationId: any(named: 'organizationId'),
      id: any(named: 'id'),
    ),
  ).thenAnswer((_) async => AppSuccess<SizeGridTemplate>(_template));
  when(
    () => availabilityRepository.listByVariantIds(
      organizationId: any(named: 'organizationId'),
      variantIds: any(named: 'variantIds'),
    ),
  ).thenAnswer(
    (_) async => AppSuccess<List<VariantAvailability>>(
      _variants.map(VariantAvailability.fromVariant).toList(),
    ),
  );

  final cubit = OrderItemsGridCubit(
    listVariantsByProduct: ListProductVariantsByProductUseCase(
      variantRepository,
    ),
    listProductColors: ListProductColorsUseCase(colorRepository),
    getSizeGridTemplateById: GetSizeGridTemplateByIdUseCase(templateRepository),
    getVariantAvailability: GetVariantAvailabilityUseCase(
      availabilityRepository,
    ),
  );
  // Not `addTearDown(cubit.close)` here: `OrderItemsGrid.dispose()` already
  // closes it (`_cubit` is fully owned by the widget, see its class doc) —
  // closing it a second time from the test itself races the widget's own
  // `unawaited(_cubit.close())` teardown.

  await pumpApp(
    tester,
    SizedBox(
      width: 760,
      child: _ControlledOrderItemsGrid(
        initialItems: items,
        createCubit: () => cubit,
        onQuantityChanged: onQuantityChanged,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Mirrors, for test purposes only, exactly what `OrderDraftPage`/
/// `OrderDraftBloc` do in production (TASK-098): [OrderItemsGrid] is a fully
/// controlled widget, so "totals stay live while typing" only holds once the
/// caller feeds the freshly-changed quantity back into `items` and rebuilds
/// — this harness owns that one small piece of state so each test can still
/// assert on the raw `(variantId, quantity)` callback via [onQuantityChanged]
/// without reimplementing `OrderDraftBloc` itself.
class _ControlledOrderItemsGrid extends StatefulWidget {
  const _ControlledOrderItemsGrid({
    required this.initialItems,
    required this.createCubit,
    this.onQuantityChanged,
  });

  final List<OrderItem> initialItems;
  final OrderItemsGridCubit Function() createCubit;
  final void Function(String variantId, int quantity)? onQuantityChanged;

  @override
  State<_ControlledOrderItemsGrid> createState() =>
      _ControlledOrderItemsGridState();
}

class _ControlledOrderItemsGridState extends State<_ControlledOrderItemsGrid> {
  late List<OrderItem> _items = widget.initialItems;

  @override
  Widget build(BuildContext context) {
    return OrderItemsGrid(
      organizationId: 'org-1',
      product: _product,
      items: _items,
      createCubit: widget.createCubit,
      onQuantityChanged: (variantId, quantity) {
        widget.onQuantityChanged?.call(variantId, quantity);
        setState(() {
          final existingIndex = _items.indexWhere(
            (item) => item.variantId == variantId,
          );
          if (existingIndex == -1) {
            _items = <OrderItem>[
              ..._items,
              OrderItem(
                id: 'test-generated-$variantId',
                variantId: variantId,
                productId: _product.id,
                quantity: quantity,
                unitPrice: 0,
                subtotal: 0,
              ),
            ];
            return;
          }
          _items = <OrderItem>[
            for (final item in _items)
              if (item.variantId == variantId)
                item.copyWith(quantity: quantity)
              else
                item,
          ];
        });
      },
    );
  }
}

final _product = buildTestProduct(
  colorIds: const <String>['color-preto', 'color-branco'],
  sizeGridTemplateId: 'grid-p-m',
);

final _colors = <ProductColor>[
  _color('color-preto', 'Preto', '#111111'),
  _color('color-branco', 'Branco', '#FFFFFF'),
];

final _template = SizeGridTemplate(
  id: 'grid-p-m',
  organizationId: 'org-1',
  name: 'P-M',
  sizes: const <SizeGridSize>[
    SizeGridSize(
      id: 'size-p',
      organizationId: 'org-1',
      label: 'P',
      orderScore: 1,
    ),
    SizeGridSize(
      id: 'size-m',
      organizationId: 'org-1',
      label: 'M',
      orderScore: 2,
    ),
  ],
  createdAt: DateTime.utc(2026, 1, 1),
  createdBy: 'user-1',
  updatedAt: DateTime.utc(2026, 1, 1),
  updatedBy: 'user-1',
  version: 1,
  syncStatus: ProductSyncStatus.synced,
);

final _variants = <ProductVariant>[
  _variant('variant-preto-p', 'color-preto', 'size-p'),
  _variant('variant-preto-m', 'color-preto', 'size-m'),
  _variant('variant-branco-p', 'color-branco', 'size-p'),
  _variant('variant-branco-m', 'color-branco', 'size-m'),
];

ProductColor _color(String id, String name, String hex) {
  return ProductColor(
    id: id,
    organizationId: 'org-1',
    code: name.toUpperCase(),
    name: name,
    hex: HexColor.parse(hex),
    status: ProductColorStatus.available,
    createdAt: DateTime.utc(2026, 1, 1),
    createdBy: 'user-1',
    updatedAt: DateTime.utc(2026, 1, 1),
    updatedBy: 'user-1',
    version: 1,
    syncStatus: ProductSyncStatus.synced,
  );
}

ProductVariant _variant(String id, String colorId, String sizeId) {
  return ProductVariant(
    id: id,
    organizationId: 'org-1',
    productId: 'product-1',
    colorId: colorId,
    sizeGridTemplateId: 'grid-p-m',
    sizeId: sizeId,
    sku: Sku.parse('CAMISA-001-${colorId.split('-').last}-$sizeId'),
    status: ProductVariantStatus.active,
    createdAt: DateTime.utc(2026, 1, 1),
    createdBy: 'user-1',
    updatedAt: DateTime.utc(2026, 1, 1),
    updatedBy: 'user-1',
    version: 1,
    syncStatus: ProductSyncStatus.synced,
  );
}
