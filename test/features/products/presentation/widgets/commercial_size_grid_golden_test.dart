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
  Future<void> expectCommercialGridGolden(
    WidgetTester tester, {
    required String name,
    required double width,
    required Map<String, VariantAvailabilityStatus> availabilityByVariantId,
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final repository =
        const SharedPreferencesCommercialSizeGridDraftRepository();
    final variantRepository = const SharedPreferencesProductVariantRepository();
    final variants = _variantsWithAvailability(availabilityByVariantId);
    for (final variant in variants) {
      await variantRepository.create(variant: variant);
    }
    final bloc = CommercialSizeGridBloc(
      getDraft: GetCommercialSizeGridDraftUseCase(repository),
      saveDraft: SaveCommercialSizeGridDraftUseCase(repository),
      getAvailability: GetVariantAvailabilityUseCase(
        ProductVariantAvailabilityRepository(variantRepository),
      ),
    );
    addTearDown(bloc.close);

    final view = tester.view;
    view.physicalSize = Size(width + 80, 620);
    view.devicePixelRatio = 1.0;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);

    await pumpApp(
      tester,
      RepaintBoundary(
        key: Key(name),
        child: SizedBox(
          width: width,
          child: BlocProvider<CommercialSizeGridBloc>.value(
            value: bloc,
            child: const CommercialSizeGrid(),
          ),
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
    await expectLater(find.byKey(Key(name)), matchesGoldenFile('$name.png'));
  }

  testWidgets('mobile without availability indicators', (tester) async {
    await expectCommercialGridGolden(
      tester,
      name: 'commercial_size_grid_mobile_ready',
      width: 375,
      availabilityByVariantId: const <String, VariantAvailabilityStatus>{},
    );
  });

  testWidgets('desktop without availability indicators', (tester) async {
    await expectCommercialGridGolden(
      tester,
      name: 'commercial_size_grid_desktop_ready',
      width: 1200,
      availabilityByVariantId: const <String, VariantAvailabilityStatus>{},
    );
  });

  testWidgets('mobile with availability indicators', (tester) async {
    await expectCommercialGridGolden(
      tester,
      name: 'commercial_size_grid_mobile_availability',
      width: 375,
      availabilityByVariantId: _availability,
    );
  });

  testWidgets('desktop with availability indicators', (tester) async {
    await expectCommercialGridGolden(
      tester,
      name: 'commercial_size_grid_desktop_availability',
      width: 1200,
      availabilityByVariantId: _availability,
    );
  });
}

const _availability = <String, VariantAvailabilityStatus>{
  'variant-preto-m': VariantAvailabilityStatus.futureStock,
  'variant-branco-m': VariantAvailabilityStatus.unavailable,
};

final _product = buildTestProduct(
  colorIds: const <String>['color-preto', 'color-branco'],
  sizeGridTemplateId: 'grid-p-m-g',
);

final _colors = <ProductColor>[
  _color('color-preto', 'Preto', '#111111'),
  _color('color-branco', 'Branco', '#FFFFFF'),
];

final _template = SizeGridTemplate(
  id: 'grid-p-m-g',
  organizationId: 'org-1',
  name: 'P-M-G',
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
    SizeGridSize(
      id: 'size-g',
      organizationId: 'org-1',
      label: 'G',
      orderScore: 3,
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
  _variant('variant-preto-g', 'color-preto', 'size-g'),
  _variant('variant-branco-p', 'color-branco', 'size-p'),
  _variant('variant-branco-m', 'color-branco', 'size-m'),
  _variant('variant-branco-g', 'color-branco', 'size-g'),
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
    sizeGridTemplateId: 'grid-p-m-g',
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
