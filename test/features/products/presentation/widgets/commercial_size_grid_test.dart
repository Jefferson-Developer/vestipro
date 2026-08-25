import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/features/products/data/repositories/product_variant_availability_repository.dart';
import 'package:vestipro/features/products/data/repositories/shared_preferences_commercial_size_grid_draft_repository.dart';
import 'package:vestipro/features/products/data/repositories/shared_preferences_product_variant_repository.dart';
import 'package:vestipro/features/products/products.dart';

import '../../../../core/design_system/components/test_pump_app.dart';
import '../../product_factory.dart';

void main() {
  group('CommercialSizeGrid', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    testWidgets('supports fast typing, keyboard navigation and live totals', (
      tester,
    ) async {
      final bloc = await _pumpGrid(tester);

      final fields = find.byType(TextField);
      await tester.enterText(fields.first, '6');
      await tester.pumpAndSettle();

      expect(bloc.state.totalQuantity, 6);
      expect(
        tester
            .widget<Text>(
              find.byKey(const Key('app_size_grid_row_total_color-preto')),
            )
            .data,
        '6',
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(const Key('app_size_grid_column_total_size-p')),
            )
            .data,
        '6',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('app_size_grid_grand_total')))
            .data,
        '6',
      );

      await tester.tap(fields.first);
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      final secondField = tester.widget<TextField>(fields.at(1));
      expect(secondField.focusNode!.hasFocus, isTrue);
    });

    testWidgets('preserves quantities when connectivity is lost', (
      tester,
    ) async {
      final bloc = await _pumpGrid(tester);

      await tester.enterText(find.byType(TextField).first, '9');
      await tester.pumpAndSettle();
      bloc.add(const CommercialSizeGridConnectivityChanged(false));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        '9',
      );
      expect(
        find.text('Offline: quantidades salvas neste dispositivo'),
        findsOneWidget,
      );
      expect(bloc.state.totalQuantity, 9);
    });

    testWidgets(
      'exposes semantic labels and visible focus for web keyboard use',
      (tester) async {
        await _pumpGrid(tester);

        expect(find.bySemanticsLabel('Preto P'), findsOneWidget);

        final field = find.byType(TextField).first;
        await tester.tap(field);
        await tester.pump();

        expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);
      },
    );
  });
}

Future<CommercialSizeGridBloc> _pumpGrid(
  WidgetTester tester, {
  Map<String, VariantAvailabilityStatus> availabilityByVariantId =
      const <String, VariantAvailabilityStatus>{},
}) async {
  final draftRepository =
      const SharedPreferencesCommercialSizeGridDraftRepository();
  final variantRepository = const SharedPreferencesProductVariantRepository();
  final variants = _variantsWithAvailability(availabilityByVariantId);
  for (final variant in variants) {
    await variantRepository.create(variant: variant);
  }
  final bloc = CommercialSizeGridBloc(
    getDraft: GetCommercialSizeGridDraftUseCase(draftRepository),
    saveDraft: SaveCommercialSizeGridDraftUseCase(draftRepository),
    getAvailability: GetVariantAvailabilityUseCase(
      ProductVariantAvailabilityRepository(variantRepository),
    ),
  );
  addTearDown(bloc.close);

  await pumpApp(
    tester,
    SizedBox(
      width: 760,
      child: BlocProvider<CommercialSizeGridBloc>.value(
        value: bloc,
        child: const CommercialSizeGrid(),
      ),
    ),
  );
  bloc.add(
    CommercialSizeGridStarted(
      product: _product,
      colors: _colors,
      sizeGridTemplate: _template,
      variants: variants,
    ),
  );
  await tester.pumpAndSettle();
  return bloc;
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

List<ProductVariant> _variantsWithAvailability(
  Map<String, VariantAvailabilityStatus> availabilityByVariantId,
) {
  return _variants
      .map(
        (variant) => variant.copyWith(
          manualAvailabilityStatus: availabilityByVariantId[variant.id],
          manualFutureAvailableAt:
              availabilityByVariantId[variant.id] ==
                  VariantAvailabilityStatus.futureStock
              ? DateTime.utc(2026, 9, 15)
              : null,
        ),
      )
      .toList(growable: false);
}

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
