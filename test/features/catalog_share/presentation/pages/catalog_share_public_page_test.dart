import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog_share/catalog_share.dart';

class _MockCatalogShareLookupRepository extends Mock
    implements CatalogShareLookupRepository {}

void main() {
  late _MockCatalogShareLookupRepository repository;

  setUp(() {
    repository = _MockCatalogShareLookupRepository();
    when(
      () => repository.registerOpen(token: any(named: 'token')),
    ).thenAnswer((_) async {});
  });

  Future<void> pumpPage(WidgetTester tester, {required String token}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: CatalogSharePublicPage(
          token: token,
          createBloc: () => CatalogSharePublicBloc(
            previewCatalogShare: PreviewCatalogShareUseCase(repository),
            registerCatalogShareOpen: RegisterCatalogShareOpenUseCase(
              repository,
            ),
            analyticsService: FakeAnalyticsService(),
          ),
        ),
      ),
    );
  }

  testWidgets('renders the shared products for a valid link', (tester) async {
    when(() => repository.preview(token: any(named: 'token'))).thenAnswer(
      (_) async => const AppSuccess(
        CatalogSharePreview(
          outcome: CatalogShareOutcome.valid,
          organizationName: 'Grupo Fashion XPTO',
          scope: CatalogShareScope.product,
          items: [
            CatalogShareItem(productId: 'product-1', name: 'Camisa Linho'),
          ],
        ),
      ),
    );

    await mockNetworkImagesFor(() async {
      await pumpPage(tester, token: 'token-1');
      await tester.pumpAndSettle();

      expect(find.text('Grupo Fashion XPTO'), findsOneWidget);
      expect(find.text('Camisa Linho'), findsOneWidget);
    });
  });

  testWidgets('shows a clear message for an expired link, never a raw error', (
    tester,
  ) async {
    when(() => repository.preview(token: any(named: 'token'))).thenAnswer(
      (_) async => const AppSuccess(
        CatalogSharePreview(outcome: CatalogShareOutcome.expired),
      ),
    );

    await pumpPage(tester, token: 'token-1');
    await tester.pumpAndSettle();

    expect(find.text('Este link expirou'), findsOneWidget);
  });

  testWidgets('shows a clear message for a revoked link', (tester) async {
    when(() => repository.preview(token: any(named: 'token'))).thenAnswer(
      (_) async => const AppSuccess(
        CatalogSharePreview(outcome: CatalogShareOutcome.revoked),
      ),
    );

    await pumpPage(tester, token: 'token-1');
    await tester.pumpAndSettle();

    expect(find.text('Este link não está mais disponível'), findsOneWidget);
  });

  testWidgets('shows a retryable error state for a technical failure', (
    tester,
  ) async {
    when(() => repository.preview(token: any(named: 'token'))).thenAnswer(
      (_) async => const AppFailure(ConnectivityFailure('Offline.')),
    );

    await pumpPage(tester, token: 'token-1');
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível abrir este link'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });
}
