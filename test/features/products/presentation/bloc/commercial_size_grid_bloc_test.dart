import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/products/data/repositories/product_variant_availability_repository.dart';
import 'package:vestipro/features/products/data/repositories/shared_preferences_commercial_size_grid_draft_repository.dart';
import 'package:vestipro/features/products/data/repositories/shared_preferences_product_variant_repository.dart';
import 'package:vestipro/features/products/products.dart';

import '../../product_factory.dart';

void main() {
  group('CommercialSizeGridBloc', () {
    late SharedPreferencesCommercialSizeGridDraftRepository draftRepository;
    late SharedPreferencesProductVariantRepository variantRepository;

    CommercialSizeGridBloc buildBloc() {
      return CommercialSizeGridBloc(
        getDraft: GetCommercialSizeGridDraftUseCase(draftRepository),
        saveDraft: SaveCommercialSizeGridDraftUseCase(draftRepository),
        getAvailability: GetVariantAvailabilityUseCase(
          ProductVariantAvailabilityRepository(variantRepository),
        ),
      );
    }

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      draftRepository =
          const SharedPreferencesCommercialSizeGridDraftRepository();
      variantRepository = const SharedPreferencesProductVariantRepository();
    });

    test('loads a persisted draft and saves every quantity change', () async {
      await _seedVariants(variantRepository, _variants);
      await draftRepository.saveDraft(
        draft: CommercialSizeGridDraft(
          organizationId: 'org-1',
          productId: 'product-1',
          quantitiesByVariantId: const <String, int>{'variant-preto-p': 3},
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      );

      final bloc = buildBloc()
        ..add(
          CommercialSizeGridStarted(
            product: _product,
            colors: _colors,
            sizeGridTemplate: _template,
            variants: _variants,
          ),
        );
      addTearDown(bloc.close);
      await _drainBloc();

      expect(bloc.state.loadStatus, CommercialSizeGridLoadStatus.ready);
      expect(bloc.state.totalQuantity, 3);

      bloc.add(
        const CommercialSizeGridQuantityChanged(
          colorId: 'color-preto',
          sizeId: 'size-m',
          quantity: 5,
        ),
      );
      await _drainBloc();

      expect(bloc.state.saveStatus, CommercialSizeGridSaveStatus.saved);
      expect(bloc.state.totalQuantity, 8);

      final persisted = await draftRepository.getDraft(
        organizationId: 'org-1',
        productId: 'product-1',
      );
      expect(
        (persisted as AppSuccess<CommercialSizeGridDraft?>)
            .value!
            .quantitiesByVariantId['variant-preto-m'],
        5,
      );
    });

    test('keeps typed quantities when connectivity changes', () async {
      await _seedVariants(variantRepository, _variants);
      final bloc = buildBloc()
        ..add(
          CommercialSizeGridStarted(
            product: _product,
            colors: _colors,
            sizeGridTemplate: _template,
            variants: _variants,
          ),
        );
      addTearDown(bloc.close);
      await _drainBloc();

      bloc
        ..add(
          const CommercialSizeGridQuantityChanged(
            colorId: 'color-preto',
            sizeId: 'size-p',
            quantity: 7,
          ),
        )
        ..add(const CommercialSizeGridConnectivityChanged(false));
      await _drainBloc();

      expect(bloc.state.isOnline, isFalse);
      expect(bloc.state.totalQuantity, 7);
    });

    test('ignores input for unavailable variants', () async {
      final unavailableVariants = <ProductVariant>[
        _variant(
          'variant-preto-p',
          'color-preto',
          'size-p',
          manualAvailabilityStatus: VariantAvailabilityStatus.unavailable,
        ),
        _variant('variant-preto-m', 'color-preto', 'size-m'),
        _variant('variant-branco-p', 'color-branco', 'size-p'),
        _variant('variant-branco-m', 'color-branco', 'size-m'),
      ];
      await _seedVariants(variantRepository, unavailableVariants);
      final bloc = buildBloc()
        ..add(
          CommercialSizeGridStarted(
            product: _product,
            colors: _colors,
            sizeGridTemplate: _template,
            variants: unavailableVariants,
          ),
        );
      addTearDown(bloc.close);
      await _drainBloc();

      bloc.add(
        const CommercialSizeGridQuantityChanged(
          colorId: 'color-preto',
          sizeId: 'size-p',
          quantity: 9,
        ),
      );
      await _drainBloc();

      expect(bloc.state.totalQuantity, 0);
    });
  });
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

ProductVariant _variant(
  String id,
  String colorId,
  String sizeId, {
  VariantAvailabilityStatus? manualAvailabilityStatus,
  DateTime? manualFutureAvailableAt,
}) {
  return ProductVariant(
    id: id,
    organizationId: 'org-1',
    productId: 'product-1',
    colorId: colorId,
    sizeGridTemplateId: 'grid-p-m',
    sizeId: sizeId,
    sku: Sku.parse('CAMISA-001-${colorId.split('-').last}-$sizeId'),
    manualAvailabilityStatus: manualAvailabilityStatus,
    manualFutureAvailableAt: manualFutureAvailableAt,
    status: ProductVariantStatus.active,
    createdAt: DateTime.utc(2026, 1, 1),
    createdBy: 'user-1',
    updatedAt: DateTime.utc(2026, 1, 1),
    updatedBy: 'user-1',
    version: 1,
    syncStatus: ProductSyncStatus.synced,
  );
}

Future<void> _drainBloc() async {
  for (var i = 0; i < 12; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Future<void> _seedVariants(
  SharedPreferencesProductVariantRepository repository,
  List<ProductVariant> variants,
) async {
  for (final variant in variants) {
    await repository.create(variant: variant);
  }
}
