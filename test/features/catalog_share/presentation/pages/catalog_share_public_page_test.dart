import 'package:cached_network_image/cached_network_image.dart';
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

  group('white-label branding (TASK-179)', () {
    testWidgets(
      'applies the organization branded primary color over the catalog',
      (tester) async {
        when(() => repository.preview(token: any(named: 'token'))).thenAnswer(
          (_) async => const AppSuccess(
            CatalogSharePreview(
              outcome: CatalogShareOutcome.valid,
              organizationName: 'Grupo Fashion XPTO',
              scope: CatalogShareScope.product,
              items: [
                CatalogShareItem(productId: 'product-1', name: 'Camisa Linho'),
              ],
              brandingPrimaryColorHex: '#0A1F33',
            ),
          ),
        );

        await mockNetworkImagesFor(() async {
          await pumpPage(tester, token: 'token-1');
          await tester.pumpAndSettle();

          final theme = Theme.of(tester.element(find.byType(Scaffold)));
          expect(theme.colorScheme.primary, const Color(0xFF0A1F33));
        });
      },
    );

    testWidgets(
      'falls back to the default theme for a malformed branding color, '
      'never crashing or leaving the page unreadable',
      (tester) async {
        when(() => repository.preview(token: any(named: 'token'))).thenAnswer(
          (_) async => const AppSuccess(
            CatalogSharePreview(
              outcome: CatalogShareOutcome.valid,
              organizationName: 'Grupo Fashion XPTO',
              scope: CatalogShareScope.product,
              items: [
                CatalogShareItem(productId: 'product-1', name: 'Camisa Linho'),
              ],
              brandingPrimaryColorHex: 'not-a-color',
            ),
          ),
        );

        await mockNetworkImagesFor(() async {
          await pumpPage(tester, token: 'token-1');
          await tester.pumpAndSettle();

          final theme = Theme.of(tester.element(find.byType(Scaffold)));
          expect(theme.colorScheme.primary, AppColors.light.primary);
          expect(find.text('Camisa Linho'), findsOneWidget);
        });
      },
    );

    testWidgets('renders the organization logo when configured', (
      tester,
    ) async {
      when(() => repository.preview(token: any(named: 'token'))).thenAnswer(
        (_) async => const AppSuccess(
          CatalogSharePreview(
            outcome: CatalogShareOutcome.valid,
            organizationName: 'Grupo Fashion XPTO',
            scope: CatalogShareScope.product,
            items: [
              CatalogShareItem(productId: 'product-1', name: 'Camisa Linho'),
            ],
            brandingLogoUrl: 'https://cdn.example.com/logo.png',
          ),
        ),
      );

      await mockNetworkImagesFor(() async {
        await pumpPage(tester, token: 'token-1');
        await tester.pumpAndSettle();

        expect(find.byType(CachedNetworkImage), findsOneWidget);
      });
    });

    testWidgets('renders no logo box at all when not configured', (
      tester,
    ) async {
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

        expect(find.byType(CachedNetworkImage), findsNothing);
      });
    });

    testWidgets(
      'each share only ever renders its own organization branding, never '
      'another organization\'s',
      (tester) async {
        when(() => repository.preview(token: any(named: 'token'))).thenAnswer(
          (_) async => const AppSuccess(
            CatalogSharePreview(
              outcome: CatalogShareOutcome.valid,
              organizationName: 'Org A',
              scope: CatalogShareScope.product,
              items: [
                CatalogShareItem(productId: 'product-1', name: 'Produto A'),
              ],
              brandingPrimaryColorHex: '#0A1F33',
            ),
          ),
        );

        await mockNetworkImagesFor(() async {
          await pumpPage(tester, token: 'token-a');
          await tester.pumpAndSettle();
          final themeA = Theme.of(tester.element(find.byType(Scaffold)));
          expect(themeA.colorScheme.primary, const Color(0xFF0A1F33));
        });

        when(() => repository.preview(token: any(named: 'token'))).thenAnswer(
          (_) async => const AppSuccess(
            CatalogSharePreview(
              outcome: CatalogShareOutcome.valid,
              organizationName: 'Org B',
              scope: CatalogShareScope.product,
              items: [
                CatalogShareItem(productId: 'product-2', name: 'Produto B'),
              ],
              brandingPrimaryColorHex: '#2B1030',
            ),
          ),
        );

        // Force a full unmount before the second pump: `CatalogSharePublicPage`
        // has no key, so re-pumping the same widget tree shape would otherwise
        // just update the existing `BlocProvider` instead of creating a fresh
        // one, hiding the very cross-organization leakage this test exists to
        // catch.
        await tester.pumpWidget(const SizedBox.shrink());

        await mockNetworkImagesFor(() async {
          await pumpPage(tester, token: 'token-b');
          await tester.pumpAndSettle();
          final themeB = Theme.of(tester.element(find.byType(Scaffold)));
          expect(themeB.colorScheme.primary, const Color(0xFF2B1030));
        });
      },
    );
  });
}
