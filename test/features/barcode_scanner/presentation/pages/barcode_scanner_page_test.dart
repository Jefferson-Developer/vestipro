import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/barcode_scanner/barcode_scanner.dart';
import 'package:vestipro/features/products/products.dart';

import '../../../products/product_factory.dart';

/// Stands in for the real camera in every widget test — `flutter test` has
/// no platform channel for `package:mobile_scanner`, so this only exposes
/// buttons that call the same [ValueChanged]/[VoidCallback] a real detection
/// would, and a marker `Key` so a test can assert whether the camera area
/// was shown at all (e.g. never shown once permission was denied).
Widget _stubCameraSurfaceBuilder(
  BuildContext context,
  ValueChanged<String> onDetect,
  VoidCallback onPermissionDenied,
  VoidCallback onUnsupported,
) {
  return Column(
    key: const Key('stub_camera_surface'),
    children: <Widget>[
      ElevatedButton(
        onPressed: () => onDetect('7891234567895'),
        child: const Text('stub: detect valid code'),
      ),
      ElevatedButton(
        onPressed: onPermissionDenied,
        child: const Text('stub: deny permission'),
      ),
    ],
  );
}

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

Widget _buildApp(
  Map<String, AppResult<ProductCodeResolution>> resolutionByCode, {
  ValueChanged<ProductCodeResolution?>? onPopped,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Builder(
      builder: (context) => ElevatedButton(
        onPressed: () async {
          final resolution = await BarcodeScannerPage.open(
            context,
            organizationId: 'org-1',
            createCubit: () => BarcodeScanCubit(
              ResolveProductCodeUseCase(
                _FakeProductCodeLookupRepository(resolutionByCode),
                FakeAnalyticsService(),
              ),
              FakeAnalyticsService(),
            ),
            cameraSurfaceBuilder: _stubCameraSurfaceBuilder,
          );
          onPopped?.call(resolution);
        },
        child: const Text('open scanner'),
      ),
    ),
  );
}

void main() {
  group('BarcodeScannerPage', () {
    testWidgets('a valid reading resolves and shows the matched product', (
      tester,
    ) async {
      final match = _buildMatch();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: BarcodeScannerPage(
            organizationId: 'org-1',
            createCubit: () => BarcodeScanCubit(
              ResolveProductCodeUseCase(
                _FakeProductCodeLookupRepository(
                  <String, AppResult<ProductCodeResolution>>{
                    '7891234567895': AppSuccess<ProductCodeResolution>(
                      ProductCodeResolution.single('7891234567895', match),
                    ),
                  },
                ),
                FakeAnalyticsService(),
              ),
              FakeAnalyticsService(),
            ),
            cameraSurfaceBuilder: _stubCameraSurfaceBuilder,
          ),
        ),
      );

      await tester.tap(find.text('stub: detect valid code'));
      await tester.pumpAndSettle();

      expect(find.text(match.product.name), findsOneWidget);
      expect(find.text('Usar este produto'), findsOneWidget);
    });

    testWidgets('an invalid/unknown reading shows a not-found message', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: BarcodeScannerPage(
            organizationId: 'org-1',
            createCubit: () => BarcodeScanCubit(
              ResolveProductCodeUseCase(
                _FakeProductCodeLookupRepository(
                  <String, AppResult<ProductCodeResolution>>{},
                ),
                FakeAnalyticsService(),
              ),
              FakeAnalyticsService(),
            ),
            cameraSurfaceBuilder: _stubCameraSurfaceBuilder,
          ),
        ),
      );

      await tester.tap(find.text('stub: detect valid code'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Código não encontrado. Confira o produto ou tente novamente.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'denying camera permission switches to the manual fallback field',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: BarcodeScannerPage(
              organizationId: 'org-1',
              createCubit: () => BarcodeScanCubit(
                ResolveProductCodeUseCase(
                  _FakeProductCodeLookupRepository(
                    <String, AppResult<ProductCodeResolution>>{},
                  ),
                  FakeAnalyticsService(),
                ),
                FakeAnalyticsService(),
              ),
              cameraSurfaceBuilder: _stubCameraSurfaceBuilder,
            ),
          ),
        );

        expect(find.byKey(const Key('stub_camera_surface')), findsOneWidget);

        await tester.tap(find.text('stub: deny permission'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('stub_camera_surface')), findsNothing);
        expect(
          find.text('Sem acesso à câmera: digite o código do produto.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'submitting a valid code through the manual fallback resolves it too',
      (tester) async {
        final match = _buildMatch();
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: BarcodeScannerPage(
              organizationId: 'org-1',
              createCubit: () => BarcodeScanCubit(
                ResolveProductCodeUseCase(
                  _FakeProductCodeLookupRepository(
                    <String, AppResult<ProductCodeResolution>>{
                      'CAM-P-AZ': AppSuccess<ProductCodeResolution>(
                        ProductCodeResolution.single('CAM-P-AZ', match),
                      ),
                    },
                  ),
                  FakeAnalyticsService(),
                ),
                FakeAnalyticsService(),
              ),
              cameraSurfaceBuilder: _stubCameraSurfaceBuilder,
            ),
          ),
        );

        await tester.tap(find.text('Digitar código manualmente'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'CAM-P-AZ');
        await tester.tap(find.text('Buscar código'));
        await tester.pumpAndSettle();

        expect(find.text(match.product.name), findsOneWidget);
      },
    );

    testWidgets(
      'confirming "Usar este produto" pops the resolution without any order/price/stock write',
      (tester) async {
        final match = _buildMatch();
        ProductCodeResolution? popped;
        await tester.pumpWidget(
          _buildApp(<String, AppResult<ProductCodeResolution>>{
            '7891234567895': AppSuccess<ProductCodeResolution>(
              ProductCodeResolution.single('7891234567895', match),
            ),
          }, onPopped: (resolution) => popped = resolution),
        );

        await tester.tap(find.text('open scanner'));
        await tester.pumpAndSettle();

        // The default (real) camera surface would need a platform channel;
        // this scenario only exercises the manual fallback + confirm button,
        // both fully testable without one.
        await tester.tap(find.text('Digitar código manualmente'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '7891234567895');
        await tester.tap(find.text('Buscar código'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Usar este produto'));
        await tester.pumpAndSettle();

        expect(popped, isNotNull);
        expect(popped!.productId, match.product.id);
      },
    );
  });
}
