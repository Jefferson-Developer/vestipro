import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog/catalog.dart';
import 'package:vestipro/features/pricing/pricing.dart';
import 'package:vestipro/features/products/data/repositories/shared_preferences_product_color_repository.dart';
import 'package:vestipro/features/products/data/repositories/shared_preferences_product_variant_repository.dart';
import 'package:vestipro/features/products/data/repositories/shared_preferences_size_grid_template_repository.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('ProductDetailPage', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    Future<ProductDetailBloc> buildBloc({
      required AppResult<Product> productResult,
      List<ProductVariant> variants = const <ProductVariant>[],
      AnalyticsService? analyticsService,
      ResolvePriceForVariantUseCase? resolvePriceForVariant,
      VariantAvailabilityRepository? availabilityRepository,
    }) async {
      final variantRepository =
          const SharedPreferencesProductVariantRepository();
      final colorRepository = const SharedPreferencesProductColorRepository();
      final templateRepository =
          const SharedPreferencesSizeGridTemplateRepository();
      for (final variant in variants) {
        await variantRepository.create(variant: variant);
      }
      await colorRepository.create(color: _colorPreto);
      await colorRepository.create(color: _colorBranco);
      await templateRepository.create(template: _template);

      return ProductDetailBloc(
        getProductById: GetProductByIdUseCase(
          _ScriptedProductRepository(productResult),
        ),
        listVariantsByProduct: ListProductVariantsByProductUseCase(
          variantRepository,
        ),
        listProductColors: ListProductColorsUseCase(colorRepository),
        getSizeGridTemplateById: GetSizeGridTemplateByIdUseCase(
          templateRepository,
        ),
        getVariantAvailability: GetVariantAvailabilityUseCase(
          availabilityRepository ?? const _FakeVariantAvailabilityRepository(),
        ),
        resolvePriceForVariant: resolvePriceForVariant,
        analyticsService: analyticsService ?? FakeAnalyticsService(),
      );
    }

    testWidgets(
      'renders gallery placeholder, colors, size grid and explicit no-price state',
      (tester) async {
        final bloc = await buildBloc(
          productResult: AppSuccess<Product>(_product),
          variants: <ProductVariant>[
            _variant('v-preto-p', 'color-preto', 'size-p'),
            _variant('v-branco-p', 'color-branco', 'size-p'),
          ],
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: ProductDetailPage(
              organizationId: 'org-1',
              productId: 'product-1',
              createBloc: () => bloc,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Camisa Essential'), findsWidgets);
        expect(find.text('Sem imagem disponível'), findsOneWidget);
        final swatchSelector = tester.widget<AppColorSwatchSelector>(
          find.byType(AppColorSwatchSelector),
        );
        expect(
          swatchSelector.options.map((option) => option.label).toSet(),
          <String>{'Preto', 'Branco'},
        );
        expect(find.text('P'), findsWidgets);
        expect(find.text('Sem preço definido na tabela ativa'), findsOneWidget);
        final button = tester.widget<AppButton>(find.byType(AppButton));
        expect(button.isDisabled, isTrue);
      },
    );

    testWidgets(
      'renders a localized future stock badge for the selected color',
      (tester) async {
        final previousLocale = Intl.defaultLocale;
        Intl.defaultLocale = 'pt_BR';
        addTearDown(() => Intl.defaultLocale = previousLocale);
        await initializeDateFormatting('pt_BR');

        final bloc = await buildBloc(
          productResult: AppSuccess<Product>(_product),
          variants: <ProductVariant>[
            _variant('v-preto-p', 'color-preto', 'size-p'),
          ],
          availabilityRepository: _FakeVariantAvailabilityRepository(
            byVariantId: <String, VariantAvailability>{
              'v-preto-p': VariantAvailability(
                variantId: 'v-preto-p',
                productId: 'product-1',
                status: VariantAvailabilityStatus.futureStock,
                futureAvailableAt: DateTime.utc(2026, 9, 15),
                futureAvailableQuantity: 24,
                futureSourceLabel: 'Compra',
              ),
            },
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: ProductDetailPage(
              organizationId: 'org-1',
              productId: 'product-1',
              createBloc: () => bloc,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.bySemanticsLabel(
            RegExp(r'Previsão: 24 un\. em 15/09/2026: warning'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'typing a quantity enables the sticky CTA, and tapping it logs product_added_to_order and forwards the lines to onAddToOrder',
      (tester) async {
        final analyticsService = FakeAnalyticsService();
        Product? addedProduct;
        List<ProductDetailOrderLine>? addedLines;

        final bloc = await buildBloc(
          productResult: AppSuccess<Product>(_product),
          variants: <ProductVariant>[
            _variant('v-preto-p', 'color-preto', 'size-p'),
          ],
          analyticsService: analyticsService,
          resolvePriceForVariant:
              _buildResolvePriceForVariantUseCase(<PriceListItem>[
                PriceListItem(
                  id: 'price-list-1::product-1::*',
                  organizationId: 'org-1',
                  companyId: 'company-1',
                  priceListId: 'price-list-1',
                  productId: 'product-1',
                  price: 199.9,
                  updatedAt: DateTime.utc(2026, 1, 1),
                  updatedBy: 'user-1',
                ),
              ]),
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: ProductDetailPage(
              organizationId: 'org-1',
              productId: 'product-1',
              createBloc: () => bloc,
              onAddToOrder: (product, lines) {
                addedProduct = product;
                addedLines = lines;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, '5');
        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.pumpAndSettle();

        final button = tester.widget<AppButton>(find.byType(AppButton));
        expect(button.isDisabled, isFalse);

        await tester.tap(find.byType(AppButton));
        await tester.pumpAndSettle();

        expect(addedProduct?.id, 'product-1');
        expect(addedLines, isNotNull);
        expect(addedLines, hasLength(1));
        expect(addedLines?.single.quantity, 5);
        final logged = analyticsService.loggedEvents.firstWhere(
          (event) => event.name == AnalyticsEvents.productAddedToOrder,
        );
        expect(logged.parameters?['product_id'], 'product-1');
        expect(logged.parameters?['items_count'], 5);
      },
    );

    testWidgets(
      'shows an explicit empty grade (never a broken screen) for a product with no active variants',
      (tester) async {
        final bloc = await buildBloc(
          productResult: AppSuccess<Product>(_product),
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: ProductDetailPage(
              organizationId: 'org-1',
              productId: 'product-1',
              createBloc: () => bloc,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Grade indisponível'), findsOneWidget);
        final button = tester.widget<AppButton>(find.byType(AppButton));
        expect(button.isDisabled, isTrue);
      },
    );

    testWidgets(
      'shows an error state with retry when the product fails to load',
      (tester) async {
        final bloc = await buildBloc(
          productResult: const AppFailure<Product>(
            NotFoundFailure('Not found.', code: 'product_not_found'),
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: ProductDetailPage(
              organizationId: 'org-1',
              productId: 'missing',
              createBloc: () => bloc,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Não foi possível carregar o produto'),
          findsOneWidget,
        );
        expect(find.text('Tentar novamente'), findsOneWidget);

        await tester.tap(find.text('Tentar novamente'));
        await tester.pumpAndSettle();

        expect(
          find.text('Não foi possível carregar o produto'),
          findsOneWidget,
        );
      },
    );
  });
}

final _product = Product(
  id: 'product-1',
  organizationId: 'org-1',
  companyId: 'company-1',
  sku: Sku.parse('CAMISA-001'),
  reference: 'REF-001',
  name: 'Camisa Essential',
  colorIds: const <String>['color-preto', 'color-branco'],
  sizeGridTemplateId: 'grid-1',
  status: ProductStatus.active,
  createdAt: DateTime.utc(2026, 1, 1),
  createdBy: 'user-1',
  updatedAt: DateTime.utc(2026, 1, 1),
  updatedBy: 'user-1',
  version: 1,
  syncStatus: ProductSyncStatus.synced,
);

final _template = SizeGridTemplate(
  id: 'grid-1',
  organizationId: 'org-1',
  name: 'P-M',
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

final _colorPreto = ProductColor(
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
);

final _colorBranco = ProductColor(
  id: 'color-branco',
  organizationId: 'org-1',
  code: 'BRANCO',
  name: 'Branco',
  hex: HexColor.parse('#FFFFFF'),
  status: ProductColorStatus.available,
  createdAt: DateTime.utc(2026, 1, 1),
  createdBy: 'user-1',
  updatedAt: DateTime.utc(2026, 1, 1),
  updatedBy: 'user-1',
  version: 1,
  syncStatus: ProductSyncStatus.synced,
);

ProductVariant _variant(String id, String colorId, String sizeId) {
  return ProductVariant(
    id: id,
    organizationId: 'org-1',
    productId: 'product-1',
    colorId: colorId,
    sizeGridTemplateId: 'grid-1',
    sizeId: sizeId,
    sku: Sku.parse('SKU-$id'),
    status: ProductVariantStatus.active,
    createdAt: DateTime.utc(2026, 1, 1),
    createdBy: 'user-1',
    updatedAt: DateTime.utc(2026, 1, 1),
    updatedBy: 'user-1',
    version: 1,
    syncStatus: ProductSyncStatus.synced,
  );
}

final class _ScriptedProductRepository implements ProductRepository {
  _ScriptedProductRepository(this._result);

  final AppResult<Product> _result;

  @override
  Future<AppResult<Product>> getById({
    required String organizationId,
    required String id,
  }) async => _result;

  @override
  Future<AppResult<bool>> existsBySku({
    required String organizationId,
    required Sku sku,
    String? excludingProductId,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<Product>> create({required Product product}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<Product>> update({required Product product}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<List<Product>>> getByIds({
    required String organizationId,
    required List<String> ids,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<List<Product>>> listRecentlyLaunched({
    required String organizationId,
    String? companyId,
    int limit = 12,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<ProductCatalogPage>> listCatalog({
    required String organizationId,
    String? companyId,
    String? cursor,
    int limit = 20,
    CatalogFilter? filter,
  }) => throw UnimplementedError();
}

final class _FakeVariantAvailabilityRepository
    implements VariantAvailabilityRepository {
  const _FakeVariantAvailabilityRepository({
    this.byVariantId = const <String, VariantAvailability>{},
  });

  final Map<String, VariantAvailability> byVariantId;

  @override
  Future<AppResult<List<VariantAvailability>>> listByVariantIds({
    required String organizationId,
    required Iterable<String> variantIds,
  }) async => AppSuccess<List<VariantAvailability>>(
    variantIds
        .map((id) => byVariantId[id])
        .whereType<VariantAvailability>()
        .toList(growable: false),
  );

  @override
  Future<AppResult<List<VariantAvailability>>> listByProductIds({
    required String organizationId,
    required Iterable<String> productIds,
  }) async =>
      const AppSuccess<List<VariantAvailability>>(<VariantAvailability>[]);
}

ResolvePriceForVariantUseCase _buildResolvePriceForVariantUseCase(
  List<PriceListItem> items,
) {
  return ResolvePriceForVariantUseCase(
    ResolveApplicablePriceListsUseCase(const _FakePriceListRepository()),
    _FakePriceListItemRepository(items),
  );
}

final class _FakePriceListRepository implements PriceListRepository {
  const _FakePriceListRepository();

  @override
  Future<AppResult<PriceList>> create({required PriceList priceList}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<PriceList?>> getById({
    required String organizationId,
    required String id,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<List<PriceList>>> listByCompany({
    required String organizationId,
    required String companyId,
  }) async => AppSuccess<List<PriceList>>(<PriceList>[
    PriceList(
      id: 'price-list-1',
      organizationId: organizationId,
      companyId: companyId,
      name: 'Tabela padrao',
      currency: 'BRL',
      validFrom: DateTime.utc(2026, 1, 1),
      status: PriceListStatus.active,
      scope: PriceListScopeType.company,
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: 'user-1',
      updatedAt: DateTime.utc(2026, 1, 1),
      updatedBy: 'user-1',
      version: 1,
      syncStatus: PriceListSyncStatus.synced,
    ),
  ]);

  @override
  Future<AppResult<PriceList>> update({required PriceList priceList}) =>
      throw UnimplementedError();
}

final class _FakePriceListItemRepository implements PriceListItemRepository {
  const _FakePriceListItemRepository(this._items);

  final List<PriceListItem> _items;

  @override
  Future<AppResult<List<PriceListItem>>> listByPriceList({
    required String organizationId,
    required String companyId,
    required String priceListId,
  }) async => AppSuccess<List<PriceListItem>>(
    _items
        .where(
          (item) =>
              item.organizationId == organizationId &&
              item.companyId == companyId &&
              item.priceListId == priceListId,
        )
        .toList(growable: false),
  );

  @override
  Future<AppResult<List<PriceListItem>>> listByProduct({
    required String organizationId,
    required String companyId,
    required String productId,
  }) async => AppSuccess<List<PriceListItem>>(
    _items
        .where(
          (item) =>
              item.organizationId == organizationId &&
              item.companyId == companyId &&
              item.productId == productId,
        )
        .toList(growable: false),
  );

  @override
  Future<AppResult<List<PriceListItem>>> upsertBatch({
    required String organizationId,
    required String companyId,
    required String priceListId,
    required List<PriceListItem> items,
    required bool confirmOverwrite,
  }) => throw UnimplementedError();
}
