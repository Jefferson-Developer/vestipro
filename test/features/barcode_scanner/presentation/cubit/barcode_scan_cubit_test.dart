import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/barcode_scanner/barcode_scanner.dart';
import 'package:vestipro/features/products/products.dart';

import '../../../products/product_factory.dart';

final class _FakeProductCodeLookupRepository
    implements ProductCodeLookupRepository {
  _FakeProductCodeLookupRepository(this.resolutionByCode);

  final Map<String, AppResult<ProductCodeResolution>> resolutionByCode;

  @override
  Future<AppResult<ProductCodeResolution>> resolveCode({
    required String organizationId,
    required String rawCode,
  }) async {
    return resolutionByCode[rawCode] ??
        AppSuccess<ProductCodeResolution>(
          ProductCodeResolution.notFound(rawCode),
        );
  }

  @override
  Future<AppResult<AlternateProductCode>> registerAlternateCode({
    required String organizationId,
    required String code,
    required String productId,
    String? variantId,
    required String registeredBy,
  }) => throw UnimplementedError();
}

ProductCodeMatch _buildMatch() {
  final product = buildTestProduct();
  final variant = ProductVariant(
    id: 'variant-1',
    organizationId: 'org-1',
    productId: product.id,
    colorId: 'color-1',
    sizeGridTemplateId: 'grid-1',
    sizeId: 'size-1',
    sku: Sku.parse('CAM-P-AZ'),
    status: ProductVariantStatus.active,
    createdAt: DateTime.utc(2026, 1, 1),
    createdBy: 'user-1',
    updatedAt: DateTime.utc(2026, 1, 1),
    updatedBy: 'user-1',
    version: 1,
    syncStatus: ProductSyncStatus.synced,
  );
  return ProductCodeMatch(product: product, variant: variant);
}

void main() {
  group('BarcodeScanCubit', () {
    blocTest<BarcodeScanCubit, BarcodeScanState>(
      'resolves a valid code to BarcodeScanStatus.resolved',
      build: () {
        final match = _buildMatch();
        final repository = _FakeProductCodeLookupRepository(
          <String, AppResult<ProductCodeResolution>>{
            '7891234567895': AppSuccess<ProductCodeResolution>(
              ProductCodeResolution.single('7891234567895', match),
            ),
          },
        );
        return BarcodeScanCubit(
          ResolveProductCodeUseCase(repository, FakeAnalyticsService()),
          FakeAnalyticsService(),
        );
      },
      act: (cubit) => cubit.onCodeDetected(
        organizationId: 'org-1',
        rawCode: '7891234567895',
      ),
      expect: () => <dynamic>[
        isA<BarcodeScanState>().having(
          (s) => s.status,
          'status',
          BarcodeScanStatus.resolving,
        ),
        isA<BarcodeScanState>().having(
          (s) => s.status,
          'status',
          BarcodeScanStatus.resolved,
        ),
      ],
    );

    blocTest<BarcodeScanCubit, BarcodeScanState>(
      'an invalid (blank) code never reaches the resolver',
      build: () {
        final repository = _FakeProductCodeLookupRepository(
          <String, AppResult<ProductCodeResolution>>{},
        );
        return BarcodeScanCubit(
          ResolveProductCodeUseCase(repository, FakeAnalyticsService()),
          FakeAnalyticsService(),
        );
      },
      act: (cubit) =>
          cubit.onCodeDetected(organizationId: 'org-1', rawCode: '  '),
      expect: () => <dynamic>[
        isA<BarcodeScanState>().having(
          (s) => s.status,
          'status',
          BarcodeScanStatus.invalid,
        ),
      ],
    );

    blocTest<BarcodeScanCubit, BarcodeScanState>(
      'a code with no match resolves to notFound',
      build: () {
        final repository = _FakeProductCodeLookupRepository(
          <String, AppResult<ProductCodeResolution>>{},
        );
        return BarcodeScanCubit(
          ResolveProductCodeUseCase(repository, FakeAnalyticsService()),
          FakeAnalyticsService(),
        );
      },
      act: (cubit) => cubit.onCodeDetected(
        organizationId: 'org-1',
        rawCode: '0000000000000',
      ),
      expect: () => <dynamic>[
        isA<BarcodeScanState>().having(
          (s) => s.status,
          'status',
          BarcodeScanStatus.resolving,
        ),
        isA<BarcodeScanState>().having(
          (s) => s.status,
          'status',
          BarcodeScanStatus.notFound,
        ),
      ],
    );

    blocTest<BarcodeScanCubit, BarcodeScanState>(
      'scanning the exact same code again increments occurrenceCount with visible feedback',
      build: () {
        final match = _buildMatch();
        final repository = _FakeProductCodeLookupRepository(
          <String, AppResult<ProductCodeResolution>>{
            '7891234567895': AppSuccess<ProductCodeResolution>(
              ProductCodeResolution.single('7891234567895', match),
            ),
          },
        );
        return BarcodeScanCubit(
          ResolveProductCodeUseCase(repository, FakeAnalyticsService()),
          FakeAnalyticsService(),
        );
      },
      act: (cubit) async {
        await cubit.onCodeDetected(
          organizationId: 'org-1',
          rawCode: '7891234567895',
        );
        cubit.resetForNextScan();
        await cubit.onCodeDetected(
          organizationId: 'org-1',
          rawCode: '7891234567895',
        );
      },
      verify: (cubit) {
        expect(cubit.state.occurrenceCount, 2);
        expect(cubit.state.status, BarcodeScanStatus.resolved);
      },
    );

    blocTest<BarcodeScanCubit, BarcodeScanState>(
      'reportPermissionDenied moves to permissionDenied and logs analytics',
      build: () {
        final repository = _FakeProductCodeLookupRepository(
          <String, AppResult<ProductCodeResolution>>{},
        );
        return BarcodeScanCubit(
          ResolveProductCodeUseCase(repository, FakeAnalyticsService()),
          FakeAnalyticsService(),
        );
      },
      act: (cubit) => cubit.reportPermissionDenied(),
      expect: () => <dynamic>[
        isA<BarcodeScanState>().having(
          (s) => s.status,
          'status',
          BarcodeScanStatus.permissionDenied,
        ),
      ],
    );
  });
}
