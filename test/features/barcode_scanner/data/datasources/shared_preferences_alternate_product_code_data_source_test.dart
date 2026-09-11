import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/features/barcode_scanner/barcode_scanner.dart';
import 'package:vestipro/features/barcode_scanner/data/datasources/shared_preferences_alternate_product_code_data_source.dart';

void main() {
  group('SharedPreferencesAlternateProductCodeDataSource', () {
    late SharedPreferencesAlternateProductCodeDataSource dataSource;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      dataSource = const SharedPreferencesAlternateProductCodeDataSource();
    });

    AlternateProductCode buildCode({
      String organizationId = 'org-1',
      String code = 'OLD-EAN-123',
      String productId = 'product-1',
      String? variantId = 'variant-1',
    }) {
      return AlternateProductCode(
        organizationId: organizationId,
        code: code,
        productId: productId,
        variantId: variantId,
        registeredAt: DateTime.utc(2026, 1, 1),
        registeredBy: 'user-1',
      );
    }

    test('findByCode returns null when nothing was registered yet', () async {
      final result = await dataSource.findByCode(
        organizationId: 'org-1',
        code: 'UNKNOWN',
      );
      expect(result, isNull);
    });

    test(
      'upsert persists a code this same instance can find without network',
      () async {
        await dataSource.upsert(buildCode());

        final found = await dataSource.findByCode(
          organizationId: 'org-1',
          code: 'OLD-EAN-123',
        );

        expect(found, isNotNull);
        expect(found!.productId, 'product-1');
        expect(found.variantId, 'variant-1');
      },
    );

    test(
      'survives a fresh instance reading from the same local store (offline persistence)',
      () async {
        await dataSource.upsert(buildCode());

        final reloaded = SharedPreferencesAlternateProductCodeDataSource();
        final found = await reloaded.findByCode(
          organizationId: 'org-1',
          code: 'OLD-EAN-123',
        );

        expect(found, isNotNull);
        expect(found!.productId, 'product-1');
      },
    );

    test('upsert of the same code replaces the previous target', () async {
      await dataSource.upsert(buildCode(productId: 'product-1'));
      await dataSource.upsert(buildCode(productId: 'product-2'));

      final found = await dataSource.findByCode(
        organizationId: 'org-1',
        code: 'OLD-EAN-123',
      );

      expect(found!.productId, 'product-2');
    });

    test('keeps the offline index isolated by organization', () async {
      await dataSource.upsert(
        buildCode(organizationId: 'org-1', code: 'CODE-1', productId: 'p-org1'),
      );
      await dataSource.upsert(
        buildCode(organizationId: 'org-2', code: 'CODE-1', productId: 'p-org2'),
      );

      final foundOrg1 = await dataSource.findByCode(
        organizationId: 'org-1',
        code: 'CODE-1',
      );
      final foundOrg2 = await dataSource.findByCode(
        organizationId: 'org-2',
        code: 'CODE-1',
      );

      expect(foundOrg1!.productId, 'p-org1');
      expect(foundOrg2!.productId, 'p-org2');
    });

    test(
      'listByOrganization lists every registered code for that organization',
      () async {
        await dataSource.upsert(buildCode(code: 'CODE-1'));
        await dataSource.upsert(buildCode(code: 'CODE-2'));
        await dataSource.upsert(
          buildCode(organizationId: 'org-2', code: 'CODE-3'),
        );

        final codes = await dataSource.listByOrganization('org-1');

        expect(
          codes.map((c) => c.code),
          containsAll(<String>['CODE-1', 'CODE-2']),
        );
        expect(codes.any((c) => c.code == 'CODE-3'), isFalse);
      },
    );
  });
}
