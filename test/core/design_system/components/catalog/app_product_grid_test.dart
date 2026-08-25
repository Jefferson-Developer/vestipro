import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:vestipro/core/design_system/design_system.dart';

import '../test_pump_app.dart';

const _shirt = AppProductCardData(
  id: 'sku-1',
  name: 'Camisa Social Slim',
  brandOrCollection: 'Coleção Verão',
  imageUrl: 'https://cdn.vestipro.test/sku-1.jpg',
  availableColorSwatches: [Colors.blue, Colors.white],
  priceLabel: 'R\$ 189,90',
  badgeLabels: ['Lançamento'],
);

/// Pumps [child] inside a scrollable ancestor — exactly how [AppProductGrid]
/// is meant to be embedded on a real screen (see its class doc, mirroring
/// `AppDataTable`'s own contract) — since the grid never scrolls itself.
Future<void> _pumpGrid(WidgetTester tester, Widget child) {
  return pumpApp(tester, SingleChildScrollView(child: child));
}

void main() {
  group('AppProductGrid', () {
    testWidgets('renders a product card with image, name and price', (
      tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await _pumpGrid(
          tester,
          AppProductGrid(products: const [_shirt], onProductTap: (_) {}),
        );

        expect(find.text('Camisa Social Slim'), findsOneWidget);
        expect(find.text('Coleção Verão'), findsOneWidget);
        expect(find.text('R\$ 189,90'), findsOneWidget);
        expect(find.text('Lançamento'), findsOneWidget);
      });
    });

    testWidgets('falls back to a placeholder icon when imageUrl is missing', (
      tester,
    ) async {
      const product = AppProductCardData(
        id: 'sku-2',
        name: 'Calça Alfaiataria',
      );

      await _pumpGrid(
        tester,
        AppProductGrid(products: const [product], onProductTap: (_) {}),
      );

      expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    });

    testWidgets('truncates a long title instead of overflowing', (
      tester,
    ) async {
      const product = AppProductCardData(
        id: 'sku-3',
        name:
            'Vestido Longo Estampado Floral Edição Limitada Coleção Primavera '
            'Verão com Detalhes Bordados à Mão',
      );

      await _pumpGrid(
        tester,
        AppProductGrid(products: const [product], onProductTap: (_) {}),
      );

      final title = tester.widget<Text>(
        find.text(product.name, findRichText: false),
      );
      expect(title.maxLines, 2);
      expect(title.overflow, TextOverflow.ellipsis);
    });

    testWidgets(
      'renders no price row when priceLabel/availability data is absent',
      (tester) async {
        const product = AppProductCardData(id: 'sku-4', name: 'Bermuda Jeans');

        await _pumpGrid(
          tester,
          AppProductGrid(products: const [product], onProductTap: (_) {}),
        );

        expect(find.textContaining('R\$'), findsNothing);
        // Availability always renders — "pronta entrega" is the safe default.
        expect(find.text('Pronta entrega'), findsOneWidget);
      },
    );

    testWidgets('shows loadingItemCount skeleton cards while loading', (
      tester,
    ) async {
      await _pumpGrid(
        tester,
        const AppProductGrid(
          products: [],
          onProductTap: _noopTap,
          status: AppProductGridStatus.loading,
          loadingItemCount: 4,
        ),
      );

      expect(find.byType(AppSkeleton), findsWidgets);
      expect(find.text('Camisa Social Slim'), findsNothing);
    });

    testWidgets('shows the empty state when status is empty', (tester) async {
      await _pumpGrid(
        tester,
        const AppProductGrid(
          products: [],
          onProductTap: _noopTap,
          status: AppProductGridStatus.empty,
          emptyTitle: 'Nenhum produto encontrado',
        ),
      );

      expect(find.text('Nenhum produto encontrado'), findsOneWidget);
    });

    testWidgets('shows the error state with retry when status is error', (
      tester,
    ) async {
      var retried = false;

      await _pumpGrid(
        tester,
        AppProductGrid(
          products: const [],
          onProductTap: (_) {},
          status: AppProductGridStatus.error,
          errorTitle: 'Não foi possível carregar o catálogo',
          retryLabel: 'Tentar novamente',
          onRetry: () => retried = true,
        ),
      );

      expect(find.text('Não foi possível carregar o catálogo'), findsOneWidget);
      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();
      expect(retried, isTrue);
    });

    testWidgets('integrates with lazy load via the load-more control', (
      tester,
    ) async {
      var loadedMore = false;

      await mockNetworkImagesFor(() async {
        await _pumpGrid(
          tester,
          AppProductGrid(
            products: const [_shirt],
            onProductTap: (_) {},
            hasMore: true,
            onLoadMore: () => loadedMore = true,
          ),
        );

        await tester.tap(find.text('Carregar mais'));
        await tester.pump();

        expect(loadedMore, isTrue);
      });
    });

    testWidgets(
      'hides the favorite button when onFavoriteTap is not provided',
      (tester) async {
        await mockNetworkImagesFor(() async {
          await _pumpGrid(
            tester,
            AppProductGrid(products: const [_shirt], onProductTap: (_) {}),
          );

          expect(find.byIcon(Icons.favorite_border), findsNothing);
          expect(find.byIcon(Icons.favorite), findsNothing);
        });
      },
    );

    testWidgets(
      'shows an outline heart for a non-favorited product and calls '
      'onFavoriteTap without triggering onProductTap (TASK-079)',
      (tester) async {
        var favoriteTapped = false;
        var productTapped = false;

        await mockNetworkImagesFor(() async {
          await _pumpGrid(
            tester,
            AppProductGrid(
              products: [
                AppProductCardData(
                  id: _shirt.id,
                  name: _shirt.name,
                  onFavoriteTap: () => favoriteTapped = true,
                ),
              ],
              onProductTap: (_) => productTapped = true,
            ),
          );

          expect(find.byIcon(Icons.favorite_border), findsOneWidget);
          expect(find.byIcon(Icons.favorite), findsNothing);

          await tester.tap(find.byIcon(Icons.favorite_border));
          await tester.pump();

          expect(favoriteTapped, isTrue);
          expect(productTapped, isFalse);
        });
      },
    );

    testWidgets(
      'shows a filled heart when isFavorite is true (TASK-079)',
      (tester) async {
        await mockNetworkImagesFor(() async {
          await _pumpGrid(
            tester,
            AppProductGrid(
              products: [
                AppProductCardData(
                  id: _shirt.id,
                  name: _shirt.name,
                  isFavorite: true,
                  onFavoriteTap: () {},
                ),
              ],
              onProductTap: (_) {},
            ),
          );

          expect(find.byIcon(Icons.favorite), findsOneWidget);
          expect(find.byIcon(Icons.favorite_border), findsNothing);
        });
      },
    );

    testWidgets('calls onProductTap with the tapped product', (tester) async {
      AppProductCardData? tapped;

      await mockNetworkImagesFor(() async {
        await _pumpGrid(
          tester,
          AppProductGrid(
            products: const [_shirt],
            onProductTap: (product) => tapped = product,
          ),
        );

        await tester.tap(find.text('Camisa Social Slim'));
        await tester.pump();

        expect(tapped?.id, _shirt.id);
      });
    });
  });
}

void _noopTap(AppProductCardData _) {}
