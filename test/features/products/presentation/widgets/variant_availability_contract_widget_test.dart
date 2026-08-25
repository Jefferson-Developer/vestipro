import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/products/data/repositories/product_variant_availability_repository.dart';
import 'package:vestipro/features/products/data/repositories/shared_preferences_commercial_size_grid_draft_repository.dart';
import 'package:vestipro/features/products/data/repositories/shared_preferences_product_variant_repository.dart';
import 'package:vestipro/features/products/products.dart';

import '../../../../core/design_system/components/test_pump_app.dart';
import '../../product_factory.dart';

void main() {
  testWidgets(
    'catalog and commercial grid render the same variant availability',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final variantRepository =
          const SharedPreferencesProductVariantRepository();
      final availabilityRepository = ProductVariantAvailabilityRepository(
        variantRepository,
      );
      await variantRepository.create(variant: _futureVariant);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ProductSearchPage(
            organizationId: 'org-1',
            initialQuery: 'camisa',
            createBloc: () => ProductSearchBloc.testing(
              searchProducts: SearchProductsUseCase(
                _FakeProductSearchRepository(products: <Product>[_product]),
              ),
              getVariantAvailability: GetVariantAvailabilityUseCase(
                availabilityRepository,
              ),
              debounceDuration: const Duration(milliseconds: 1),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Estoque futuro 15/09/2026'), findsOneWidget);

      final draftRepository =
          const SharedPreferencesCommercialSizeGridDraftRepository();
      final gridBloc = CommercialSizeGridBloc(
        getDraft: GetCommercialSizeGridDraftUseCase(draftRepository),
        saveDraft: SaveCommercialSizeGridDraftUseCase(draftRepository),
        getAvailability: GetVariantAvailabilityUseCase(availabilityRepository),
      );
      addTearDown(gridBloc.close);

      await pumpApp(
        tester,
        SizedBox(
          width: 520,
          child: BlocProvider<CommercialSizeGridBloc>.value(
            value: gridBloc,
            child: const CommercialSizeGrid(),
          ),
        ),
      );
      gridBloc.add(
        CommercialSizeGridStarted(
          product: _product,
          colors: _colors,
          sizeGridTemplate: _template,
          variants: <ProductVariant>[_futureVariant],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Preto P: Estoque futuro 15/09/2026'),
        findsOneWidget,
      );
    },
  );
}

final _product = buildTestProduct(
  colorIds: const <String>['color-preto'],
  sizeGridTemplateId: 'grid-p',
);

final _colors = <ProductColor>[
  ProductColor(
    id: 'color-preto',
    organizationId: 'org-1',
    code: 'PRETO',
    name: 'Preto',
    hex: HexColor.parse('#111111'),
    status: ProductColorStatus.available,
    createdAt: DateTime.utc(2026, 1, 1),
    createdBy: 'user-1',
    updatedAt: DateTime.utc(2026, 1, 1),
    updatedBy: 'user-1',
    version: 1,
    syncStatus: ProductSyncStatus.synced,
  ),
];

final _template = SizeGridTemplate(
  id: 'grid-p',
  organizationId: 'org-1',
  name: 'P',
  sizes: const <SizeGridSize>[
    SizeGridSize(
      id: 'size-p',
      organizationId: 'org-1',
      label: 'P',
      orderScore: 1,
    ),
  ],
  createdAt: DateTime.utc(2026, 1, 1),
  createdBy: 'user-1',
  updatedAt: DateTime.utc(2026, 1, 1),
  updatedBy: 'user-1',
  version: 1,
  syncStatus: ProductSyncStatus.synced,
);

final _futureVariant = ProductVariant(
  id: 'variant-preto-p',
  organizationId: 'org-1',
  productId: 'product-1',
  colorId: 'color-preto',
  sizeGridTemplateId: 'grid-p',
  sizeId: 'size-p',
  sku: Sku.parse('CAMISA-001-PRETO-P'),
  manualAvailabilityStatus: VariantAvailabilityStatus.futureStock,
  manualAvailableQuantity: 12,
  manualFutureAvailableAt: DateTime.utc(2026, 9, 15),
  status: ProductVariantStatus.active,
  createdAt: DateTime.utc(2026, 1, 1),
  createdBy: 'user-1',
  updatedAt: DateTime.utc(2026, 1, 1),
  updatedBy: 'user-1',
  version: 1,
  syncStatus: ProductSyncStatus.synced,
);

final class _FakeProductSearchRepository implements ProductSearchRepository {
  const _FakeProductSearchRepository({required this.products});

  final List<Product> products;

  @override
  Future<AppResult<ProductSearchResult>> searchProducts({
    required String organizationId,
    required String query,
    ProductSearchSource source = ProductSearchSource.remote,
    int limit = 20,
  }) async {
    return AppSuccess<ProductSearchResult>(
      ProductSearchResult(
        products: products,
        source: source,
        normalizedQuery: ProductSearchNormalizer.normalize(query),
      ),
    );
  }
}
