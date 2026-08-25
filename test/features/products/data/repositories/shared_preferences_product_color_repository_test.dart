import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/products/data/repositories/shared_preferences_product_color_repository.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('SharedPreferencesProductColorRepository', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('persists color palettes isolated by organization', () async {
      const repository = SharedPreferencesProductColorRepository();
      final create = CreateProductColorUseCase(
        repository,
        const ProductColorSimilarityService(),
      );
      final list = ListProductColorsUseCase(repository);

      await create(
        id: 'color-org-1',
        organizationId: 'org-1',
        code: 'PRE',
        name: 'Preto',
        hex: '#000000',
        createdBy: 'user-1',
      );
      await create(
        id: 'color-org-2',
        organizationId: 'org-2',
        code: 'PRE',
        name: 'Preto',
        hex: '#000000',
        createdBy: 'user-2',
      );

      final org1 =
          (await list('org-1') as AppSuccess<List<ProductColor>>).value;
      final org2 =
          (await list('org-2') as AppSuccess<List<ProductColor>>).value;

      expect(org1.map((color) => color.id), <String>['color-org-1']);
      expect(org2.map((color) => color.id), <String>['color-org-2']);
    });

    test('keeps EAN uniqueness scoped to the organization', () async {
      const repository = SharedPreferencesProductColorRepository();
      final create = CreateProductColorUseCase(
        repository,
        const ProductColorSimilarityService(),
      );

      final org1Result = await create(
        id: 'color-org-1',
        organizationId: 'org-1',
        code: 'AZM',
        name: 'Azul Marinho',
        hex: '#102A44',
        eans: const <String>['4006381333931'],
        createdBy: 'user-1',
      );
      final org2Result = await create(
        id: 'color-org-2',
        organizationId: 'org-2',
        code: 'AZM',
        name: 'Azul Marinho',
        hex: '#102A44',
        eans: const <String>['4006381333931'],
        createdBy: 'user-2',
      );
      final duplicateResult = await create(
        id: 'color-org-1-copy',
        organizationId: 'org-1',
        code: 'AZM2',
        name: 'Azul Marinho 2',
        hex: '#102A45',
        eans: const <String>['4006381333931'],
        createdBy: 'user-1',
        confirmedSimilarColor: true,
      );

      expect(org1Result, isA<AppSuccess<ProductColor>>());
      expect(org2Result, isA<AppSuccess<ProductColor>>());
      expect(duplicateResult, isA<AppFailure<ProductColor>>());
    });
  });
}
