import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/barcode_scanner/barcode_scanner.dart';
import 'package:vestipro/features/products/products.dart';

import '../../../products/product_factory.dart';

final class _FakeProductCodeLookupRepository
    implements ProductCodeLookupRepository {
  _FakeProductCodeLookupRepository(this._resolveResult);

  final AppResult<ProductCodeResolution> _resolveResult;
  int resolveCallCount = 0;
  String? lastRawCode;

  @override
  Future<AppResult<ProductCodeResolution>> resolveCode({
    required String organizationId,
    required String rawCode,
  }) async {
    resolveCallCount += 1;
    lastRawCode = rawCode;
    return _resolveResult;
  }

  @override
  Future<AppResult<AlternateProductCode>> registerAlternateCode({
    required String organizationId,
    required String code,
    required String productId,
    String? variantId,
    required String registeredBy,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  group('ResolveProductCodeUseCase', () {
    test('fails without calling the repository for a blank rawCode', () async {
      final repository = _FakeProductCodeLookupRepository(
        AppSuccess<ProductCodeResolution>(
          ProductCodeResolution.notFound('irrelevant'),
        ),
      );
      final analytics = FakeAnalyticsService();
      final useCase = ResolveProductCodeUseCase(repository, analytics);

      final result = await useCase(organizationId: 'org-1', rawCode: '   ');

      expect(result, isA<AppFailure<ProductCodeResolution>>());
      expect(
        (result as AppFailure<ProductCodeResolution>).failure.code,
        'invalid_product_code_resolution_payload',
      );
      expect(repository.resolveCallCount, 0);
      expect(analytics.loggedEvents, isEmpty);
    });

    test(
      'fails without calling the repository for a blank organizationId',
      () async {
        final repository = _FakeProductCodeLookupRepository(
          AppSuccess<ProductCodeResolution>(
            ProductCodeResolution.notFound('7891234567895'),
          ),
        );
        final analytics = FakeAnalyticsService();
        final useCase = ResolveProductCodeUseCase(repository, analytics);

        final result = await useCase(
          organizationId: '  ',
          rawCode: '7891234567895',
        );

        expect(result, isA<AppFailure<ProductCodeResolution>>());
        expect(repository.resolveCallCount, 0);
      },
    );

    test(
      'delegates to the repository and logs the resolution outcome',
      () async {
        final product = buildTestProduct();
        final variant = ProductVariant(
          id: 'variant-1',
          organizationId: 'org-1',
          productId: product.id,
          colorId: 'color-1',
          sizeGridTemplateId: 'grid-1',
          sizeId: 'size-1',
          sku: Sku.parse('CAM-BAS-001-P-AZ'),
          status: ProductVariantStatus.active,
          createdAt: DateTime.utc(2026, 1, 1),
          createdBy: 'user-1',
          updatedAt: DateTime.utc(2026, 1, 1),
          updatedBy: 'user-1',
          version: 1,
          syncStatus: ProductSyncStatus.synced,
        );
        final repository = _FakeProductCodeLookupRepository(
          AppSuccess<ProductCodeResolution>(
            ProductCodeResolution.single(
              '7891234567895',
              ProductCodeMatch(product: product, variant: variant),
            ),
          ),
        );
        final analytics = FakeAnalyticsService();
        final useCase = ResolveProductCodeUseCase(repository, analytics);

        final result = await useCase(
          organizationId: 'org-1',
          rawCode: '7891234567895',
        );

        expect(result, isA<AppSuccess<ProductCodeResolution>>());
        expect(repository.lastRawCode, '7891234567895');
        expect(
          analytics.loggedEvents.single.name,
          AnalyticsEvents.barcodeScanResolved,
        );
        expect(
          analytics.loggedEvents.single.parameters?['resolution_status'],
          'singleMatch',
        );
        // The raw scanned code itself is never logged.
        expect(
          analytics.loggedEvents.single.parameters?.values,
          isNot(contains('7891234567895')),
        );
      },
    );

    test('logs notFound without failing', () async {
      final repository = _FakeProductCodeLookupRepository(
        AppSuccess<ProductCodeResolution>(
          ProductCodeResolution.notFound('0000000000000'),
        ),
      );
      final analytics = FakeAnalyticsService();
      final useCase = ResolveProductCodeUseCase(repository, analytics);

      final result = await useCase(
        organizationId: 'org-1',
        rawCode: '0000000000000',
      );

      expect(result, isA<AppSuccess<ProductCodeResolution>>());
      expect(
        analytics.loggedEvents.single.parameters?['resolution_status'],
        'notFound',
      );
    });

    test('does not log analytics when the repository fails', () async {
      final repository = _FakeProductCodeLookupRepository(
        const AppFailure<ProductCodeResolution>(
          UnexpectedFailure('boom', code: 'product_code_resolve_unexpected'),
        ),
      );
      final analytics = FakeAnalyticsService();
      final useCase = ResolveProductCodeUseCase(repository, analytics);

      final result = await useCase(
        organizationId: 'org-1',
        rawCode: '7891234567895',
      );

      expect(result, isA<AppFailure<ProductCodeResolution>>());
      expect(analytics.loggedEvents, isEmpty);
    });
  });
}
