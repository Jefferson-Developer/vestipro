import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog/catalog.dart';
import 'package:vestipro/features/products/data/repositories/shared_preferences_product_color_repository.dart';
import 'package:vestipro/features/products/data/repositories/shared_preferences_product_variant_repository.dart';
import 'package:vestipro/features/products/data/repositories/shared_preferences_size_grid_template_repository.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('ProductDetailBloc', () {
    late FakeAnalyticsService analyticsService;
    late SharedPreferencesProductVariantRepository variantRepository;
    late SharedPreferencesProductColorRepository colorRepository;
    late SharedPreferencesSizeGridTemplateRepository templateRepository;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      analyticsService = FakeAnalyticsService();
      variantRepository = const SharedPreferencesProductVariantRepository();
      colorRepository = const SharedPreferencesProductColorRepository();
      templateRepository = const SharedPreferencesSizeGridTemplateRepository();
      await templateRepository.create(template: _template);
      await colorRepository.create(color: _colorPreto);
      await colorRepository.create(color: _colorBranco);
    });

    ProductDetailBloc buildBloc({
      required _ScriptedProductRepository productRepository,
      VariantAvailabilityRepository? availabilityRepository,
    }) {
      return ProductDetailBloc(
        getProductById: GetProductByIdUseCase(productRepository),
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
        analyticsService: analyticsService,
      );
    }

    blocTest<ProductDetailBloc, ProductDetailState>(
      'loads product, variants, colors, template and availability in one '
      'consistent state, selecting the first color with variants',
      setUp: () async {
        await variantRepository.create(
          variant: _variant('v-preto-p', 'color-preto', 'size-p'),
        );
        await variantRepository.create(
          variant: _variant('v-preto-m', 'color-preto', 'size-m'),
        );
        await variantRepository.create(
          variant: _variant('v-branco-p', 'color-branco', 'size-p'),
        );
      },
      build: () => buildBloc(
        productRepository: _ScriptedProductRepository(
          AppSuccess<Product>(_product),
        ),
      ),
      act: (bloc) => bloc.add(
        const ProductDetailStarted(
          organizationId: 'org-1',
          productId: 'product-1',
          origin: 'search',
        ),
      ),
      expect: () => <Object>[
        isA<ProductDetailState>().having(
          (state) => state.status,
          'status',
          ProductDetailLoadStatus.loading,
        ),
        isA<ProductDetailState>()
            .having(
              (state) => state.status,
              'status',
              ProductDetailLoadStatus.success,
            )
            .having((state) => state.product?.id, 'product', 'product-1')
            .having((state) => state.variants.length, 'variants', 3)
            .having(
              (state) => state.selectedColorId,
              'selectedColorId',
              'color-preto',
            )
            .having(
              (state) => state.hasAvailabilityWarning,
              'hasAvailabilityWarning',
              isFalse,
            )
            .having(
              (state) => state.isPriceAvailable,
              'isPriceAvailable',
              isFalse,
            ),
        isA<ProductDetailState>().having(
          (state) => state.hasLoggedViewed,
          'hasLoggedViewed',
          isTrue,
        ),
      ],
      verify: (_) {
        final logged = analyticsService.loggedEvents.firstWhere(
          (event) => event.name == AnalyticsEvents.productViewed,
        );
        expect(logged.parameters?['product_id'], 'product-1');
        expect(logged.parameters?['source'], 'search');
      },
    );

    blocTest<ProductDetailBloc, ProductDetailState>(
      'fails the whole screen when the product itself cannot be loaded',
      build: () => buildBloc(
        productRepository: _ScriptedProductRepository(
          const AppFailure<Product>(
            NotFoundFailure('Not found.', code: 'product_not_found'),
          ),
        ),
      ),
      act: (bloc) => bloc.add(
        const ProductDetailStarted(
          organizationId: 'org-1',
          productId: 'missing',
        ),
      ),
      expect: () => <Object>[
        isA<ProductDetailState>().having(
          (state) => state.status,
          'status',
          ProductDetailLoadStatus.loading,
        ),
        isA<ProductDetailState>()
            .having(
              (state) => state.status,
              'status',
              ProductDetailLoadStatus.failure,
            )
            .having(
              (state) => state.failure,
              'failure',
              isA<NotFoundFailure>(),
            ),
      ],
    );

    blocTest<ProductDetailBloc, ProductDetailState>(
      'degrades gracefully when availability fails to load: falls back to '
      'VariantAvailability.fromVariant and flags an explicit warning '
      '(never a silently confirmed "pronta entrega")',
      setUp: () async {
        await variantRepository.create(
          variant: _variant('v-preto-p', 'color-preto', 'size-p'),
        );
      },
      build: () => buildBloc(
        productRepository: _ScriptedProductRepository(
          AppSuccess<Product>(_product),
        ),
        availabilityRepository: const _FailingVariantAvailabilityRepository(),
      ),
      act: (bloc) => bloc.add(
        const ProductDetailStarted(
          organizationId: 'org-1',
          productId: 'product-1',
        ),
      ),
      skip: 1,
      expect: () => <Object>[
        isA<ProductDetailState>()
            .having(
              (state) => state.status,
              'status',
              ProductDetailLoadStatus.success,
            )
            .having(
              (state) => state.hasAvailabilityWarning,
              'hasAvailabilityWarning',
              isTrue,
            )
            .having(
              (state) => state.variants.isEmpty
                  ? null
                  : state.availabilityForVariant(state.variants.first).status,
              'fallback availability',
              VariantAvailabilityStatus.readyStock,
            ),
        isA<ProductDetailState>(),
      ],
    );

    blocTest<ProductDetailBloc, ProductDetailState>(
      'exposes an explicit empty grade when the product has no active '
      'variants, never a broken/blank screen',
      build: () => buildBloc(
        productRepository: _ScriptedProductRepository(
          AppSuccess<Product>(_product),
        ),
      ),
      act: (bloc) => bloc.add(
        const ProductDetailStarted(
          organizationId: 'org-1',
          productId: 'product-1',
        ),
      ),
      skip: 1,
      expect: () => <Object>[
        isA<ProductDetailState>()
            .having(
              (state) => state.hasNoPurchasableVariants,
              'hasNoPurchasableVariants',
              isTrue,
            )
            .having((state) => state.colorOptions, 'colorOptions', isEmpty)
            .having(
              (state) => state.selectedColorId,
              'selectedColorId',
              isNull,
            ),
        isA<ProductDetailState>(),
      ],
    );

    blocTest<ProductDetailBloc, ProductDetailState>(
      'preserves quantities typed for one color when switching to another '
      'color and back (offline/connection-drop safe)',
      setUp: () async {
        await variantRepository.create(
          variant: _variant('v-preto-p', 'color-preto', 'size-p'),
        );
        await variantRepository.create(
          variant: _variant('v-branco-p', 'color-branco', 'size-p'),
        );
      },
      build: () => buildBloc(
        productRepository: _ScriptedProductRepository(
          AppSuccess<Product>(_product),
        ),
      ),
      act: (bloc) async {
        bloc.add(
          const ProductDetailStarted(
            organizationId: 'org-1',
            productId: 'product-1',
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const ProductDetailQuantityChanged(
            colorId: 'color-preto',
            sizeId: 'size-p',
            quantity: 4,
          ),
        );
        bloc.add(const ProductDetailColorSelected('color-branco'));
        bloc.add(
          const ProductDetailQuantityChanged(
            colorId: 'color-branco',
            sizeId: 'size-p',
            quantity: 2,
          ),
        );
        bloc.add(const ProductDetailColorSelected('color-preto'));
      },
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.selectedColorId, 'color-preto');
        expect(bloc.state.totalQuantity, 6);
        expect(bloc.state.orderLines.length, 2);
      },
    );

    blocTest<ProductDetailBloc, ProductDetailState>(
      'ignores quantity typed for a variant that cannot accept stock',
      setUp: () async {
        await variantRepository.create(
          variant: _variant(
            'v-preto-p',
            'color-preto',
            'size-p',
            manualAvailabilityStatus: VariantAvailabilityStatus.unavailable,
          ),
        );
      },
      build: () => buildBloc(
        productRepository: _ScriptedProductRepository(
          AppSuccess<Product>(_product),
        ),
      ),
      act: (bloc) async {
        bloc.add(
          const ProductDetailStarted(
            organizationId: 'org-1',
            productId: 'product-1',
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const ProductDetailQuantityChanged(
            colorId: 'color-preto',
            sizeId: 'size-p',
            quantity: 9,
          ),
        );
      },
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.totalQuantity, 0);
      },
    );

    blocTest<ProductDetailBloc, ProductDetailState>(
      'logs product_added_to_order with the total items typed across colors',
      setUp: () async {
        await variantRepository.create(
          variant: _variant('v-preto-p', 'color-preto', 'size-p'),
        );
        await variantRepository.create(
          variant: _variant('v-branco-p', 'color-branco', 'size-p'),
        );
      },
      build: () => buildBloc(
        productRepository: _ScriptedProductRepository(
          AppSuccess<Product>(_product),
        ),
      ),
      act: (bloc) async {
        bloc.add(
          const ProductDetailStarted(
            organizationId: 'org-1',
            productId: 'product-1',
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const ProductDetailQuantityChanged(
            colorId: 'color-preto',
            sizeId: 'size-p',
            quantity: 3,
          ),
        );
        bloc.add(const ProductDetailAddToOrderRequested());
      },
      wait: const Duration(milliseconds: 10),
      verify: (_) {
        final logged = analyticsService.loggedEvents.firstWhere(
          (event) => event.name == AnalyticsEvents.productAddedToOrder,
        );
        expect(logged.parameters?['product_id'], 'product-1');
        expect(logged.parameters?['items_count'], 3);
      },
    );

    blocTest<ProductDetailBloc, ProductDetailState>(
      'does nothing and logs nothing when the CTA is tapped with no '
      'quantity typed',
      build: () => buildBloc(
        productRepository: _ScriptedProductRepository(
          AppSuccess<Product>(_product),
        ),
      ),
      act: (bloc) async {
        bloc.add(
          const ProductDetailStarted(
            organizationId: 'org-1',
            productId: 'product-1',
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ProductDetailAddToOrderRequested());
      },
      wait: const Duration(milliseconds: 10),
      verify: (_) {
        expect(
          analyticsService.loggedEvents.map((event) => event.name),
          isNot(contains(AnalyticsEvents.productAddedToOrder)),
        );
      },
    );
  });
}

final _product = Product(
  id: 'product-1',
  organizationId: 'org-1',
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

ProductVariant _variant(
  String id,
  String colorId,
  String sizeId, {
  VariantAvailabilityStatus? manualAvailabilityStatus,
}) {
  return ProductVariant(
    id: id,
    organizationId: 'org-1',
    productId: 'product-1',
    colorId: colorId,
    sizeGridTemplateId: 'grid-1',
    sizeId: sizeId,
    sku: Sku.parse('SKU-$id'),
    manualAvailabilityStatus: manualAvailabilityStatus,
    status: ProductVariantStatus.active,
    createdAt: DateTime.utc(2026, 1, 1),
    createdBy: 'user-1',
    updatedAt: DateTime.utc(2026, 1, 1),
    updatedBy: 'user-1',
    version: 1,
    syncStatus: ProductSyncStatus.synced,
  );
}

/// Scripted [ProductRepository] whose only exercised method is `getById` —
/// every other method throws, so a test using it fails loudly instead of
/// silently succeeding if `ProductDetailBloc` is ever changed to call one.
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
  const _FakeVariantAvailabilityRepository();

  @override
  Future<AppResult<List<VariantAvailability>>> listByVariantIds({
    required String organizationId,
    required Iterable<String> variantIds,
  }) async =>
      const AppSuccess<List<VariantAvailability>>(<VariantAvailability>[]);

  @override
  Future<AppResult<List<VariantAvailability>>> listByProductIds({
    required String organizationId,
    required Iterable<String> productIds,
  }) async =>
      const AppSuccess<List<VariantAvailability>>(<VariantAvailability>[]);
}

final class _FailingVariantAvailabilityRepository
    implements VariantAvailabilityRepository {
  const _FailingVariantAvailabilityRepository();

  @override
  Future<AppResult<List<VariantAvailability>>> listByVariantIds({
    required String organizationId,
    required Iterable<String> variantIds,
  }) async => const AppFailure<List<VariantAvailability>>(
    UnexpectedFailure('offline', code: 'availability_unavailable'),
  );

  @override
  Future<AppResult<List<VariantAvailability>>> listByProductIds({
    required String organizationId,
    required Iterable<String> productIds,
  }) async => const AppFailure<List<VariantAvailability>>(
    UnexpectedFailure('offline', code: 'availability_unavailable'),
  );
}
